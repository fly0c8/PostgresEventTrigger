CREATE OR REPLACE FUNCTION notify_event() RETURNS TRIGGER AS $$

    DECLARE 
        data json;
        notification json;
    
    BEGIN
    
        -- Convert the old or new row to JSON, based on the kind of action.
        -- Action = DELETE?             -> OLD row
        -- Action = INSERT or UPDATE?   -> NEW row
        IF (TG_OP = 'DELETE') THEN
            data = row_to_json(OLD);
        ELSE
            data = row_to_json(NEW);
        END IF;
        
        -- Contruct the notification as a JSON string.
        notification = json_build_object(
                          'table',TG_TABLE_NAME,
                          'action', TG_OP,
                          'data', data);
        
                        
        -- Execute pg_notify(channel, notification)
        PERFORM pg_notify('events',notification::text);
        
        -- Result is ignored since this is an AFTER trigger
        RETURN NULL; 
    END;
    
$$ LANGUAGE plpgsql;

CREATE TABLE products (
  id SERIAL,
  name TEXT,
  quantity FLOAT
);

CREATE TRIGGER products_notify_event
AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW EXECUTE PROCEDURE notify_event();


-- exampledb=# LISTEN events;
-- LISTEN
-- exampledb=# INSERT INTO products (name, quantity)
-- exampledb-# VALUES ('pen', 10200);
-- INSERT 0 1
-- Asynchronous notification "events" with payload "{"table" : "products", 
--   "action" : "INSERT", "data" : {"id":1,"name":"pen","quantity":10200}}" 
--   received from server process with PID 799.
-- exampledb=#