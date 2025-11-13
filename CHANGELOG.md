# Changelog

All notable changes to the Maryland BOE Spending Database project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added - 2024-11-13

#### Documentation
- **README.md**: Comprehensive project documentation including:
  - Project overview and features
  - Technology stack description
  - Installation and setup instructions
  - Usage examples and queries
  - Data processing pipeline explanation
  - Development and deployment guides
  - Data sources and references

- **DATA_UPDATE.md**: Detailed data update plan including:
  - Step-by-step update procedures
  - Data source URLs and API endpoints
  - OpenRefine deduplication workflow
  - Quality assurance checklists
  - Troubleshooting guide
  - Future automation recommendations

- **.gitignore**: Ignore patterns for:
  - Large CSV and database files
  - Python and R temporary files
  - IDE configurations
  - OS-specific files

- **CHANGELOG.md**: This file for tracking project changes

#### Repository Structure
- Reorganized files into logical directory structure:
  ```
  data/
  ├── raw/           # Source data from counties and state
  ├── intermediate/  # Processing intermediates
  ├── processed/     # Final cleaned data
  └── reference/     # Lookup tables and crosswalks

  databases/         # SQLite database files
  templates/         # Datasette custom templates
  ```

### Changed - 2024-11-13

#### Scripts
- **boe_setup.sh**: Updated to use new directory structure
  - Database now created in `databases/` directory
  - References `data/processed/` for cleaned CSV
  - Added progress messages and error handling
  - Added database optimization (vacuum) step
  - Added comments for clarity

- **boe_spending.Rmd**: Updated all file paths to use new structure
  - Raw data loaded from `data/raw/`
  - Intermediate outputs saved to `data/intermediate/`
  - Final processed data saved to `data/processed/`
  - Reference files loaded from `data/reference/`
  - Added conditional check for exclude.csv existence

### Moved - 2024-11-13

#### Data Files
Moved all data files from root directory to organized subdirectories:

**To data/raw/**
- County_Board_of_Education_-_Spending_Disclosures.csv
- baltimore_county_2021.csv
- baltimore_county_2022.csv
- baltimore_city_2021.csv
- anne_arundel_replacement.csv
- montgomery_2019.csv
- carroll_2022.csv
- Howard_County_Payee.csv
- Kent2021.csv
- FY21 Vendors 25k+.xlsm
- Montgomery County Paula DBM MCPS edit FY 2019.xlsx
- clean_aacps_boe_spending.csv

**To data/intermediate/**
- boe_spending.csv
- boe_427.csv
- boe_515.csv
- boe_spending_cleaned_for_refine.csv

**To data/processed/**
- boe_spending_cleaned.csv
- boe_spending_cleaned.bak.csv
- boe_final.csv
- BOE-Final.csv

**To data/reference/**
- boe-payees-final.csv
- unique_payee_name_clean.csv
- boe_fips_crosswalk.csv

**To databases/**
- boe_spending.db
- boe_spending2.db

---

## Previous Changes

### 2024 (Pre-reorganization)

#### Fixed
- Header logo display
- CSS styling issues
- Download language improvements
- Table template formatting

#### Updated
- Merged latest changes
- Updated deduplication process
- Added Baltimore City and Baltimore County data
- Template styling improvements

---

## Data Updates by Fiscal Year

### FY 2022
- Baltimore County 2022 data added
- Complete coverage for 24 counties + Baltimore City

### FY 2021
- Baltimore County 2021 data added
- Baltimore City 2021 data added
- Kent County 2021 data added
- Carroll County 2022 data added

### FY 2020
- Anne Arundel replacement data
- Montgomery County FY 2019 corrections

### FY 2019
- Initial historical data
- Montgomery County special handling

---

## Future Enhancements

### Planned
- [ ] Automated data download script
- [ ] GitHub Actions workflow for updates
- [ ] Data validation tests
- [ ] API endpoint for programmatic access
- [ ] Additional filter options (payment purpose categories)
- [ ] Vendor search with fuzzy matching
- [ ] Year-over-year comparison tools
- [ ] Data visualization dashboard
- [ ] Export to additional formats (Excel, JSON)

### Under Consideration
- [ ] Historical trend analysis
- [ ] Geographic visualization (by county)
- [ ] Vendor category classification
- [ ] Mobile app version
- [ ] Email alerts for new data

---

**Maintainers**: CNS Maryland, Philip Merrill College of Journalism, University of Maryland
