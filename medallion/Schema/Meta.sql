USE OlistDW;
GO

CREATE TABLE meta.etl_run (
    run_id          BIGINT IDENTITY(1,1)    PRIMARY KEY,
    pipeline_name   NVARCHAR(400)           NOT NULL,
    run_start_utc   DATETIME2               NOT NULL    DEFAULT SYSUTCDATETIME(),
    run_end_utc     DATETIME2               NULL,
    run_status      NVARCHAR(60)            NOT NULL    DEFAULT 'RUNNING',
    triggered_by    NVARCHAR(200)           NOT NULL    DEFAULT 'manual',
    notes           NVARCHAR(2000)          NULL
);
GO

CREATE TABLE meta.etl_audit (
    audit_id        BIGINT IDENTITY(1,1)    PRIMARY KEY,
    run_id          BIGINT                  NOT NULL,
    layer_name      NVARCHAR(40)            NOT NULL,
    object_name     NVARCHAR(512)           NOT NULL,
    step_name       NVARCHAR(400)           NOT NULL,
    row_count       BIGINT                  NULL,
    event_time_utc  DATETIME2               NOT NULL    DEFAULT SYSUTCDATETIME(),
    status          NVARCHAR(60)            NOT NULL,
    message         NVARCHAR(4000)          NULL
);
GO

CREATE TABLE meta.qa_results (
    qa_id           BIGINT IDENTITY(1,1)    PRIMARY KEY,
    run_id          BIGINT                  NOT NULL,
    layer_name      NVARCHAR(40)            NOT NULL,
    object_name     NVARCHAR(512)           NOT NULL,
    check_name      NVARCHAR(400)           NOT NULL,
    severity        NVARCHAR(40)            NOT NULL,
    status          NVARCHAR(20)            NOT NULL,
    failing_rows    BIGINT                  NOT NULL    DEFAULT 0,
    sample_query    NVARCHAR(4000)          NULL,
    created_utc     DATETIME2               NOT NULL    DEFAULT SYSUTCDATETIME()
);
GO