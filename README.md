# Contracted Out: Maryland Board of Education Spending Database

A searchable database of Maryland Board of Education vendor payment disclosures, making public school spending information accessible and transparent.

**Live Site:** [md-boe-spending.herokuapp.com](http://md-boe-spending.herokuapp.com)

## Overview

This project aggregates and publishes vendor payment data from 24 Maryland counties and Baltimore City, covering fiscal years 2019-2022. The database contains over 2.8 million payment records totaling billions in public education spending, searchable by vendor name, school district, and fiscal year.

## Features

- **Full-Text Search**: Search across vendor names and payment purposes
- **Faceted Browsing**: Filter by school district, fiscal year, and zip code
- **CSV Export**: Download filtered results for further analysis
- **Responsive Design**: Mobile-friendly interface
- **Fast Performance**: SQLite-backed database with optimized queries

## Data Coverage

### School Districts (25)
- 24 Maryland Counties: Allegany, Anne Arundel, Baltimore, Calvert, Caroline, Carroll, Cecil, Charles, Dorchester, Frederick, Garrett, Harford, Howard, Kent, Montgomery, Prince George's, Queen Anne's, St. Mary's, Somerset, Talbot, Washington, Wicomico, Worcester
- Baltimore City Public Schools

### Time Period
- Fiscal Years 2019-2022
- Payments of $25,000 or more (per state disclosure requirements)

### Data Fields
- **Agency Name**: School district name
- **Fiscal Year**: 2019-2022
- **Payee Name**: Vendor/recipient (deduplicated and standardized)
- **Payee Zip Code**: 5-digit zip code
- **Amount**: Payment amount in dollars
- **Purpose**: Payment category (Baltimore County only)

## Technology Stack

### Backend
- **[Datasette](https://datasette.io/)**: Interactive database publishing platform
- **SQLite**: Lightweight, file-based database
- **Python 3.10**: Runtime environment

### Data Processing
- **R + Tidyverse**: Data cleaning and transformation
- **[R Janitor](https://sfirke.github.io/janitor/)**: Data cleaning utilities
- **[OpenRefine](https://openrefine.org/)**: Entity deduplication and normalization
- **[sqlite-utils](https://sqlite-utils.datasette.io/)**: SQLite database management

### Frontend
- **Bootstrap 5**: Responsive CSS framework
- **Jinja2**: Template engine (via Datasette)
- **Custom Templates**: Branded interface with CNS Maryland styling

### Deployment
- **Heroku**: Cloud hosting platform
- **Git**: Version control

## Installation

### Prerequisites
- Python 3.10+
- R 4.0+ (for data processing)
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/NewsAppsUMD/boe_spending.git
   cd boe_spending
   ```

2. **Install Python dependencies**
   ```bash
   pip install pipenv
   pipenv install
   pipenv shell
   ```

3. **Install R packages** (if processing data)
   ```r
   install.packages(c("tidyverse", "janitor"))
   ```

4. **Run Datasette locally**
   ```bash
   datasette boe_spending.db
   ```

5. **Open in browser**
   Navigate to `http://localhost:8001`

## Usage

### Searching the Database

**Basic Search:**
- Enter vendor name in the search box (e.g., "Apple", "Amazon")
- Results show all matching payment records

**Filtering:**
- Click "Facets" to filter by school district or fiscal year
- Use the search bar to find specific vendors or payment purposes

**Exporting Data:**
- Click "CSV" or "JSON" to download results
- Options include streaming exports for large datasets

### Example Queries

**Find all payments to a vendor:**
```
Search: "AMAZON"
```

**View a specific district's spending:**
```
Filter: agency_name = "MONTGOMERY COUNTY PUBLIC SCHOOLS"
```

**Payments in a specific year:**
```
Filter: fiscal_year = 2022
```

## Data Processing Pipeline

The project follows this workflow to transform raw data into a searchable database:

```
Raw County CSVs → R Processing → OpenRefine → SQLite → Datasette → Heroku
```

### 1. Data Collection
- Download source data from Maryland Open Data Portal
- Collect supplemental county-specific datasets (Baltimore City/County)
- Store in `data/raw/` directory

### 2. Data Cleaning (`boe_spending.Rmd`)
- Standardize agency names (fix typos, capitalization)
- Clean vendor names (remove suffixes, punctuation)
- Aggregate individual payments by vendor/year
- Filter for payments >= $25,000
- Create URL slugs for districts
- Output: `data/intermediate/boe_spending.csv`

### 3. Entity Deduplication (OpenRefine)
- Manual review of vendor name variations
- Merge entities (e.g., "APPLE INC" + "APPLE COMPUTERS" → "APPLE INC")
- Output: `data/processed/boe_final.csv`

### 4. Database Creation (`boe_setup.sh`)
- Import cleaned CSV to SQLite
- Enable full-text search on vendor names and payment purposes
- Type casting (amounts to float)
- Output: `boe_spending.db`

### 5. Deployment
- Publish database to Heroku using Datasette
- Custom templates applied automatically

## Development

### Project Structure

```
boe_spending/
├── README.md                      # Project documentation
├── DATA_UPDATE.md                 # Data update procedures
├── boe_setup.sh                   # Database build & deployment script
├── boe_spending.Rmd              # R data processing pipeline
├── Pipfile / Pipfile.lock        # Python dependencies
├── data/                         # Data directory
│   ├── raw/                      # Source data files
│   ├── intermediate/             # Processing intermediates
│   ├── processed/                # Final cleaned data
│   └── reference/                # Lookup tables, crosswalks
├── databases/                    # SQLite database files
│   └── boe_spending.db
└── templates/                    # Datasette custom templates
    ├── base.html                 # Main layout + branding
    ├── table.html                # Table view template
    ├── _table.html               # Custom table styling
    └── row.html                  # Row detail template
```

### Making Changes

**Updating templates:**
1. Edit files in `templates/` directory
2. Test locally: `datasette boe_spending.db --template-dir templates/`
3. Commit changes
4. Redeploy to Heroku

**Processing new data:**
1. Add source files to `data/raw/`
2. Update `boe_spending.Rmd` to include new data
3. Run R notebook to process
4. Run OpenRefine for entity deduplication
5. Rebuild database with `boe_setup.sh`

## Deployment

### Deploy to Heroku

```bash
# First time setup
heroku login
heroku git:remote -a md-boe-spending

# Deploy updated database
bash boe_setup.sh
```

The setup script:
1. Removes old database
2. Installs dependencies
3. Creates new SQLite database
4. Enables full-text search
5. Publishes to Heroku

### Manual Deployment

```bash
# Build database
sqlite-utils insert boe_spending.db vendors data/processed/boe_spending_cleaned.csv --csv
sqlite-utils transform boe_spending.db vendors --type amount float
sqlite-utils enable-fts boe_spending.db vendors payee_name purpose_of_payment_baltimore_county_only

# Deploy to Heroku
datasette publish heroku boe_spending.db -n md-boe-spending --template-dir templates/
```

## Data Sources

### Primary Source
**Maryland Open Data Portal**
- Dataset: [County Board of Education - Spending Disclosures](https://opendata.maryland.gov/Education/County-Board-of-Education-Spending-Disclosures/t6vk-rvwe)
- Dataset ID: `t6vk-rvwe`
- Format: CSV via Socrata API
- Update Frequency: Annually (after fiscal year end)

### Supplemental Sources
- **Baltimore County**: Individual transaction records (aggregated to $25K+)
- **Baltimore City**: Vendor payment summaries
- **Anne Arundel County**: Corrected/updated records
- **Montgomery County**: FY2019 replacement data

## Data Update Plan

See [DATA_UPDATE.md](DATA_UPDATE.md) for detailed instructions on updating the database with new fiscal year data.

## Contributing

This project is maintained by CNS Maryland (Philip Merrill College of Journalism, University of Maryland).

**To report issues or suggest improvements:**
1. Open an issue on GitHub
2. Contact: [Contact information for project maintainers]

## License

This project is provided for educational and transparency purposes. Data is sourced from public records provided by the State of Maryland.

## Acknowledgments

- **Data Source**: Maryland State Department of Education, Maryland Transparency Portal
- **Project Team**: CNS Maryland, Philip Merrill College of Journalism
- **Technology**: Built with [Datasette](https://datasette.io/) by Simon Willison

## Related Resources

- [Maryland Transparency Portal](https://mtp.maryland.gov/)
- [Maryland Open Data Portal](https://opendata.maryland.gov/)
- [Datasette Documentation](https://docs.datasette.io/)
- [Socrata Open Data API](https://dev.socrata.com/)

---

**Last Updated**: November 2024
