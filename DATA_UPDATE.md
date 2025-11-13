# Data Update Plan

This document provides detailed instructions for updating the Maryland Board of Education spending database with new fiscal year data.

## Table of Contents
- [Overview](#overview)
- [Data Sources](#data-sources)
- [Update Schedule](#update-schedule)
- [Step-by-Step Update Process](#step-by-step-update-process)
- [Automated Update (Future Enhancement)](#automated-update-future-enhancement)
- [Troubleshooting](#troubleshooting)
- [Data Quality Checks](#data-quality-checks)

## Overview

The database should be updated annually after each fiscal year ends (Maryland fiscal year runs July 1 - June 30). Counties are required to submit spending disclosures to the state, which aggregates them into the central dataset.

**Update Frequency**: Annually (typically available by September/October)
**Last Updated**: FY 2022 (data through June 30, 2022)
**Next Update Due**: FY 2023 data (expected Fall 2024)

## Data Sources

### Primary Data Source

**Maryland Open Data Portal - County Board of Education Spending Disclosures**

- **URL**: https://opendata.maryland.gov/Education/County-Board-of-Education-Spending-Disclosures/t6vk-rvwe
- **Dataset ID**: `t6vk-rvwe`
- **Platform**: Socrata Open Data API (SODA)
- **Format**: CSV, JSON

#### Download Methods

**Method 1: Direct CSV Download**
```bash
curl -o data/raw/County_Board_of_Education_-_Spending_Disclosures.csv \
  "https://opendata.maryland.gov/api/views/t6vk-rvwe/rows.csv?accessType=DOWNLOAD"
```

**Method 2: Socrata API (with filtering)**
```bash
# Example: Get only FY 2023 data
curl "https://opendata.maryland.gov/resource/t6vk-rvwe.csv?\$where=fiscal_year=2023" \
  -o data/raw/boe_spending_2023.csv
```

**Method 3: Web Browser**
- Visit the dataset page
- Click "Export" → "CSV"
- Save to `data/raw/` directory

### Supplemental Data Sources

Some counties provide additional detail or corrections that should be incorporated:

#### Baltimore County
- **Source**: Baltimore County Open Data Portal
- **URL**: https://opendata.baltimorecountymd.gov/
- **Notes**: Provides individual transaction records; must be aggregated to $25K+ threshold

#### Baltimore City
- **Contact**: Baltimore City Public Schools Finance Department
- **Notes**: May require direct request; not always in state dataset

#### Anne Arundel County
- **Notes**: Historical corrections/replacements may be needed
- **Contact**: Anne Arundel County Public Schools

#### Montgomery County
- **Notes**: FY 2019 data required special handling
- **Contact**: Montgomery County Public Schools

## Update Schedule

| Task | Timeline | Responsibility |
|------|----------|---------------|
| Check for new FY data | September 1 | Data team |
| Download source data | Within 1 week of availability | Data team |
| Process and clean data | 1-2 weeks | Data analyst |
| Entity deduplication | 1 week | Data analyst |
| QA/Testing | 3-5 days | Data team + Editor |
| Deploy to production | After QA approval | Data engineer |
| Announce update | Same day as deploy | Editorial |

## Step-by-Step Update Process

### Step 1: Download New Data

**A. Primary Dataset**

```bash
# Navigate to project directory
cd /path/to/boe_spending

# Download latest data with timestamp
DATE=$(date +%Y%m%d)
curl -o "data/raw/boe_spending_${DATE}.csv" \
  "https://opendata.maryland.gov/api/views/t6vk-rvwe/rows.csv?accessType=DOWNLOAD"

# Create backup of current data
cp data/raw/County_Board_of_Education_-_Spending_Disclosures.csv \
   data/raw/County_Board_of_Education_-_Spending_Disclosures_backup_${DATE}.csv

# Replace with new data
mv "data/raw/boe_spending_${DATE}.csv" \
   data/raw/County_Board_of_Education_-_Spending_Disclosures.csv
```

**B. Check for Supplemental County Data**

Contact or check websites for:
- Baltimore County individual transaction files
- Baltimore City vendor summaries
- Any county-specific corrections/updates

Save supplemental files to `data/raw/` with naming convention:
- `{county_name}_{fiscal_year}.csv`
- Example: `baltimore_county_2023.csv`

### Step 2: Update Processing Script

Edit `boe_spending.Rmd` to include new fiscal year data:

```r
# Add new fiscal year data if needed
# Example for Baltimore County 2023:

baltimore_county_2023 <- read_csv("data/raw/baltimore_county_2023.csv") %>%
  clean_names()

baltimore_county_2023_totals <- baltimore_county_2023 %>%
  group_by(fiscal_year, agency_name, payee_name, payee_zip,
           purpose_of_payment_baltimore_county_only) %>%
  summarize(total = sum(amount)) %>%
  filter(total >= 25000) %>%
  rename(amount = total)

boe_spending <- bind_rows(boe_spending, baltimore_county_2023_totals)
```

### Step 3: Run Data Processing

**Open RStudio or R console:**

```r
# Set working directory
setwd("/path/to/boe_spending")

# Load required packages
library(tidyverse)
library(janitor)

# Run the R Markdown notebook
rmarkdown::render("boe_spending.Rmd")
```

This will:
1. Load and combine all source files
2. Standardize agency names
3. Clean vendor names
4. Apply county-specific replacements
5. Create URL slugs
6. Output: `data/intermediate/boe_spending.csv`

### Step 4: Entity Deduplication (OpenRefine)

This is the most time-consuming but critical step for data quality.

**Install OpenRefine** (if not already installed):
- Download from: https://openrefine.org/
- Extract and run: `./refine` (Mac/Linux) or `openrefine.exe` (Windows)

**OpenRefine Process:**

1. **Create New Project**
   - Open OpenRefine (usually http://localhost:3333)
   - Click "Create Project" → "Choose Files"
   - Select `data/intermediate/boe_spending.csv`
   - Click "Next" → "Create Project"

2. **Cluster Payee Names**
   - Click dropdown on `payee_name_clean` column
   - Select "Edit cells" → "Cluster and edit..."
   - Method: "key collision" / "fingerprint"
   - Review suggested merges (e.g., "APPLE INC" + "APPLE INCORPORATED")
   - Check "Merge?" for valid duplicates
   - Click "Merge Selected & Re-Cluster"
   - Repeat with other methods:
     - "ngram-fingerprint"
     - "metaphone3"
     - "cologne-phonetic"

3. **Manual Review**
   - Create text facet on `payee_name_clean`
   - Sort by count (descending)
   - Manually review top 500-1000 vendors
   - Look for variations:
     - Different abbreviations (INC, INCORPORATED, CORP, CORPORATION)
     - Punctuation differences
     - Spacing issues
     - Typos

4. **Create Refined Column**
   - Click dropdown on `payee_name_clean`
   - Select "Edit column" → "Add column based on this column"
   - Name: `payee_name_refined`
   - Expression: `value`
   - This preserves your deduplicated names

5. **Export Results**
   - Click "Export" → "Comma-separated value"
   - Save as: `data/processed/boe_final.csv`

### Step 5: Final Data Preparation

Back in R, load the OpenRefine results:

```r
# Load OpenRefine output
boe_final <- read_csv("data/processed/boe_final.csv") %>%
  filter(fiscal_year > 2018)

# Clean any remaining issues
boe_final <- boe_final %>%
  mutate(payee_name = str_replace_all(payee_name, "\u00A0", " "))

# Load exclusion list (if maintaining one for data quality flags)
exclude <- read_csv("data/reference/exclude.csv") %>% distinct()
boe_final <- boe_final %>%
  left_join(exclude) %>%
  mutate(exclude = if_else(is.na(exclude), FALSE, TRUE))

# Write final cleaned data
write_csv(boe_final, "data/processed/boe_spending_cleaned.csv")
```

### Step 6: Build Database

Run the updated deployment script:

```bash
bash boe_setup.sh
```

This will:
1. Remove old database
2. Create new SQLite database from cleaned CSV
3. Set proper data types (amount as float)
4. Enable full-text search on vendor names and payment purposes

### Step 7: Test Locally

```bash
# Start Datasette locally
datasette databases/boe_spending.db --template-dir templates/

# Open in browser: http://localhost:8001
```

**Test Cases:**
- [ ] Search for known vendor (e.g., "AMAZON")
- [ ] Filter by new fiscal year
- [ ] Check each county has expected record counts
- [ ] Verify amounts display correctly (currency formatting)
- [ ] Test CSV export
- [ ] Check mobile responsive layout
- [ ] Verify faceted browsing works

### Step 8: Data Quality Checks

Run these queries to verify data integrity:

```bash
# Install sqlite-utils if needed
pip install sqlite-utils

# Check record counts by fiscal year
sqlite-utils query databases/boe_spending.db \
  "SELECT fiscal_year, COUNT(*) as count FROM vendors GROUP BY fiscal_year ORDER BY fiscal_year"

# Check record counts by agency
sqlite-utils query databases/boe_spending.db \
  "SELECT agency_name, COUNT(*) as count FROM vendors GROUP BY agency_name ORDER BY count DESC"

# Find potential data quality issues
sqlite-utils query databases/boe_spending.db \
  "SELECT * FROM vendors WHERE amount IS NULL OR amount < 0 LIMIT 100"

# Check for missing critical fields
sqlite-utils query databases/boe_spending.db \
  "SELECT COUNT(*) FROM vendors WHERE payee_name IS NULL OR agency_name IS NULL"
```

**Expected Results:**
- All 24 counties + Baltimore City represented
- Each county has data for FY 2019-2023 (or latest available)
- No negative amounts
- No NULL values in critical fields
- Payment amounts >= $25,000 (per disclosure requirement)

### Step 9: Deploy to Production

```bash
# Deploy to Heroku
datasette publish heroku databases/boe_spending.db \
  -n md-boe-spending \
  --template-dir templates/ \
  --setting sql_time_limit_ms 10000 \
  --setting facet_time_limit_ms 2000

# Or use the setup script which does this automatically
bash boe_setup.sh
```

**Post-Deployment Checks:**
- [ ] Visit production URL: http://md-boe-spending.herokuapp.com
- [ ] Verify new fiscal year data appears
- [ ] Test search and filtering
- [ ] Check analytics tracking (Parse.ly)
- [ ] Test on mobile device

### Step 10: Document and Announce

1. **Update README.md**
   - Update "Last Updated" date
   - Update fiscal year range in data coverage section

2. **Git Commit**
   ```bash
   git add .
   git commit -m "Update database to include FY 2023 data"
   git push origin main
   ```

3. **Announce Update**
   - Post on social media
   - Send to stakeholder list
   - Update any related stories/articles

## Automated Update (Future Enhancement)

To reduce manual work, consider automating the update process:

### Option 1: GitHub Actions Workflow

Create `.github/workflows/update-data.yml`:

```yaml
name: Update BOE Spending Data

on:
  schedule:
    # Run monthly on the 1st at 6 AM UTC
    - cron: '0 6 1 * *'
  workflow_dispatch:  # Allow manual trigger

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Set up R
        uses: r-lib/actions/setup-r@v2

      - name: Install R dependencies
        run: |
          R -e 'install.packages(c("tidyverse", "janitor", "rmarkdown"))'

      - name: Download latest data
        run: |
          curl -o data/raw/County_Board_of_Education_-_Spending_Disclosures.csv \
            "https://opendata.maryland.gov/api/views/t6vk-rvwe/rows.csv?accessType=DOWNLOAD"

      - name: Process data
        run: Rscript -e "rmarkdown::render('boe_spending.Rmd')"

      - name: Check for changes
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            echo "NEW_DATA=true" >> $GITHUB_ENV
          fi

      - name: Notify if new data
        if: env.NEW_DATA == 'true'
        run: |
          echo "New data available! Manual review required for OpenRefine step."
          # Add notification webhook here (Slack, email, etc.)
```

### Option 2: Heroku Scheduler

Add a scheduled job to check for new data:

```bash
# Install Heroku Scheduler addon
heroku addons:create scheduler:standard -a md-boe-spending

# Add job to run daily
# Command: python scripts/check_for_updates.py
```

**Note**: Full automation is challenging due to the OpenRefine deduplication step, which requires human judgment. Consider this as a semi-automated notification system.

## Troubleshooting

### Issue: Download fails with 403 error

**Solution**: The Maryland Open Data Portal may have rate limiting or require user agent headers.

```bash
curl -H "User-Agent: Mozilla/5.0" \
  -o data/raw/boe_spending.csv \
  "https://opendata.maryland.gov/api/views/t6vk-rvwe/rows.csv?accessType=DOWNLOAD"
```

### Issue: County name mismatches after update

**Symptoms**: A county appears to have no data for new fiscal year.

**Solution**: Check for county name variations in new data:

```r
# In R console
boe_spending %>%
  distinct(agency_name) %>%
  arrange(agency_name) %>%
  print(n = 30)
```

Add any new variations to the `case_when()` statement in `boe_spending.Rmd`:

```r
mutate(agency_name = case_when(
  agency_name == 'NEW VARIATION HERE' ~ 'STANDARDIZED NAME',
  TRUE ~ agency_name
))
```

### Issue: Deployment fails on Heroku

**Error**: `Database file too large`

**Solution**: Heroku has a 1GB slug size limit. Compress the database or upgrade to a larger dyno.

```bash
# Vacuum the database to reduce size
sqlite-utils vacuum databases/boe_spending.db

# Or use Heroku's hobby tier with more space
heroku dyno:type hobby -a md-boe-spending
```

### Issue: Some vendors missing after deduplication

**Cause**: Over-aggressive clustering in OpenRefine merged distinct entities.

**Solution**:
1. Review the OpenRefine project history
2. Undo problematic merge operations
3. Be more conservative with automated clustering
4. Focus manual review on high-payment vendors (>$100K)

### Issue: Full-text search not working

**Error**: No results when searching for known vendors.

**Solution**: Rebuild the full-text search index:

```bash
sqlite-utils enable-fts databases/boe_spending.db vendors \
  payee_name purpose_of_payment_baltimore_county_only \
  --replace
```

## Data Quality Checks

### Pre-Deployment Checklist

- [ ] All 25 agencies (24 counties + Baltimore City) have data
- [ ] New fiscal year records present
- [ ] No NULL values in required fields (agency_name, fiscal_year, payee_name, amount)
- [ ] All amounts >= $25,000 (except exempted categories)
- [ ] No negative amounts
- [ ] Payee names deduplicated (no obvious duplicates in top 100 vendors)
- [ ] ZIP codes are 5 digits (or NULL)
- [ ] Fiscal years are reasonable (2019-present)
- [ ] Total payment amounts seem reasonable compared to previous years
- [ ] Agency name slugs are correct and URL-safe
- [ ] Database file size is reasonable (<100MB compressed)

### Post-Deployment Verification

- [ ] Website loads and displays data
- [ ] Search functionality works
- [ ] Filters and facets work correctly
- [ ] CSV export works
- [ ] Mobile layout is responsive
- [ ] Page load time is acceptable (<3 seconds)
- [ ] Analytics tracking is working (Parse.ly)
- [ ] No JavaScript errors in browser console
- [ ] Links in navigation work
- [ ] New fiscal year data is visible and searchable

## Contact Information

For questions or issues with data updates:

- **Project Lead**: [Name/Email]
- **Data Team**: [Email]
- **Technical Issues**: [GitHub Issues](https://github.com/NewsAppsUMD/boe_spending/issues)

## Additional Resources

- [Maryland Open Data Portal](https://opendata.maryland.gov/)
- [Socrata API Documentation](https://dev.socrata.com/)
- [Datasette Documentation](https://docs.datasette.io/)
- [OpenRefine Documentation](https://docs.openrefine.org/)
- [Maryland State Education Disclosure Laws](https://mtp.maryland.gov/)

---

**Last Updated**: November 2024
