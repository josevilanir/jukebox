#!/bin/bash
# Grant SUPERUSER to the 'rails' PostgreSQL role so Rails can disable FK
# constraints during fixture loading in tests.
sudo -u postgres psql -c "ALTER ROLE rails SUPERUSER;"
echo "Done! Now run: bin/rails test"
