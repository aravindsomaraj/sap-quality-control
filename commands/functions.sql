CREATE OR REPLACE FUNCTION get_passed_samples()
RETURNS TABLE (sample_id integer) AS
$$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s.sample_id
    FROM sample s
    JOIN test t ON s.sample_id = t.sample_id
    WHERE s.sample_status IN ('In-progress', 'Completed')
    GROUP BY s.sample_id
    HAVING NOT EXISTS (
        SELECT 1
        FROM test t2
        WHERE t2.sample_id = s.sample_id AND t2.in_spec_status = false
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_failed_samples()
RETURNS TABLE (sample_id integer) AS
$$
BEGIN
    RETURN QUERY
    SELECT DISTINCT s.sample_id
	FROM sample s
	LEFT JOIN test t USING(sample_id)
	WHERE s.sample_status = 'Cancelled' OR (
		s.sample_status IN ('In-progress', 'Completed') AND t.in_spec_status = false);
END;
$$
LANGUAGE plpgsql;

UPDATE batch
SET release_status = 'Withheld'
WHERE batch_id IN (
	SELECT batch_id
	FROM sample
	NATURAL JOIN inspection
	WHERE sample_id IN (
		SELECT sample_id FROM get_failed_samples())
);



CREATE OR REPLACE FUNCTION get_unreceived_samples()
RETURNS TABLE (sample_id integer) AS
$$
BEGIN
    RETURN QUERY
	SELECT DISTINCT s.sample_id
	FROM sample s
	WHERE s.sample_status = 'Unreceived';
END;
$$
LANGUAGE plpgsql;


CREATE TABLE delay
(
	id int PRIMARY KEY,
	batch_id char(6),
	Reason text,
	FOREIGN KEY (batch_id) REFERENCES batch(batch_id)
);

INSERT INTO delay
VALUES
(1,'ARD124','OOS in Assay Test'),
(2,'ARD125','OOS Investigation Delay'),
(3,'ARD126','Loss of Sample'),
(4,'ARD129','OOS in pH, Dissolution tests'),
(5,'ARW130','Sample not received'),
(6,'ARW132','Loss of Sample');



CREATE OR REPLACE FUNCTION get_unreleased_lots()
RETURNS TABLE (InspectionID char(5),BatchID char(6),Product_Name varchar(10), Manufacturer varchar(20),
			   Manufacturing_Date char(10),Expiry_Date char(10), Release_Date char(10),
			   Product_Type varchar(15)) AS
$$
BEGIN
    RETURN QUERY
    SELECT i.inspection_id,batch_id,p.product_name,p.manufacturer,p.manu_date,p.expiry_date,p.release_date,p.product_type
	FROM inspection i
	NATURAL JOIN product p
	WHERE p.release_date > TO_CHAR(NOW()::date, 'yyyy/mm/dd');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_all_batches()
RETURNS TABLE (Batch_id char(6),Release_status varchar, Delay_reason text) AS
$$
BEGIN
    RETURN QUERY
    SELECT b.batch_id,b.release_status,d.reason
	FROM batch b
	LEFT JOIN delay d USING(batch_id)
	ORDER BY batch_id;
END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_sample_details(id char(6))
RETURNS TABLE (inspection_id char(6),sample_status varchar(15),test_method varchar(20),Analyst_name varchar(25),analysis_date char(10),In_spec_status boolean) AS
$$
BEGIN
    RETURN QUERY
    SELECT s.inspection_id,s.sample_status,t.test_name,a.name,t.analysis_date,t.in_spec_status
	FROM sample s
	LEFT JOIN test t using(sample_id)
	LEFT JOIN analyst a USING(analyst_id)
	WHERE s.inspection_id = id;
END;
$$
LANGUAGE plpgsql;