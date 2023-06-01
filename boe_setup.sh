rm -f boe_spending.db
pip install sqlite-utils datasette
sqlite-utils insert boe_spending.db vendors boe_spending_cleaned.csv --csv
sqlite-utils transform boe_spending.db vendors --type amount float
sqlite-utils enable-fts boe_spending.db vendors payee_name purpose_of_payment_baltimore_county_only
datasette publish heroku boe_spending.db -n md-boe-spending
