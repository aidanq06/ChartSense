# SQL migrations

Apply `0001_init.sql` to bootstrap the schema.

To apply locally:

```bash
psql postgres://chartsense:chartsense@localhost:5432/chartsense -f sql/0001_init.sql
```

Future migrations should be added as `0002_*.sql`, `0003_*.sql`, etc.


