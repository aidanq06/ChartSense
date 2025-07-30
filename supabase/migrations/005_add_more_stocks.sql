-- Add more stocks to the database for comprehensive stock selection
INSERT INTO public.stocks (symbol, company_name, sector, industry) VALUES
-- Technology
('ADBE', 'Adobe Inc.', 'Technology', 'Software'),
('CRM', 'Salesforce Inc.', 'Technology', 'Software'),
('ORCL', 'Oracle Corporation', 'Technology', 'Software'),
('INTC', 'Intel Corporation', 'Technology', 'Semiconductors'),
('AMD', 'Advanced Micro Devices Inc.', 'Technology', 'Semiconductors'),
('QCOM', 'Qualcomm Incorporated', 'Technology', 'Semiconductors'),
('AVGO', 'Broadcom Inc.', 'Technology', 'Semiconductors'),
('CSCO', 'Cisco Systems Inc.', 'Technology', 'Communication Equipment'),
('IBM', 'International Business Machines Corp.', 'Technology', 'Software'),
('TXN', 'Texas Instruments Incorporated', 'Technology', 'Semiconductors'),

-- Consumer Cyclical
('HD', 'The Home Depot Inc.', 'Consumer Cyclical', 'Home Improvement Retail'),
('MCD', 'McDonald''s Corporation', 'Consumer Cyclical', 'Restaurants'),
('NKE', 'NIKE Inc.', 'Consumer Cyclical', 'Footwear & Accessories'),
('SBUX', 'Starbucks Corporation', 'Consumer Cyclical', 'Restaurants'),
('DIS', 'The Walt Disney Company', 'Communication Services', 'Entertainment'),
('CMCSA', 'Comcast Corporation', 'Communication Services', 'Entertainment'),
('VZ', 'Verizon Communications Inc.', 'Communication Services', 'Telecom Services'),
('T', 'AT&T Inc.', 'Communication Services', 'Telecom Services'),

-- Healthcare
('PFE', 'Pfizer Inc.', 'Healthcare', 'Drug Manufacturers'),
('UNH', 'UnitedHealth Group Incorporated', 'Healthcare', 'Healthcare Plans'),
('ABBV', 'AbbVie Inc.', 'Healthcare', 'Drug Manufacturers'),
('MRK', 'Merck & Co. Inc.', 'Healthcare', 'Drug Manufacturers'),
('TMO', 'Thermo Fisher Scientific Inc.', 'Healthcare', 'Medical Devices'),
('DHR', 'Danaher Corporation', 'Healthcare', 'Medical Devices'),
('ABT', 'Abbott Laboratories', 'Healthcare', 'Medical Devices'),
('LLY', 'Eli Lilly and Company', 'Healthcare', 'Drug Manufacturers'),

-- Financial Services
('BAC', 'Bank of America Corp.', 'Financial Services', 'Banks'),
('WFC', 'Wells Fargo & Company', 'Financial Services', 'Banks'),
('GS', 'The Goldman Sachs Group Inc.', 'Financial Services', 'Capital Markets'),
('MS', 'Morgan Stanley', 'Financial Services', 'Capital Markets'),
('BLK', 'BlackRock Inc.', 'Financial Services', 'Asset Management'),
('AXP', 'American Express Company', 'Financial Services', 'Credit Services'),
('V', 'Visa Inc.', 'Financial Services', 'Credit Services'),
('MA', 'Mastercard Incorporated', 'Financial Services', 'Credit Services'),

-- Consumer Defensive
('PG', 'The Procter & Gamble Company', 'Consumer Defensive', 'Household & Personal Products'),
('KO', 'The Coca-Cola Company', 'Consumer Defensive', 'Beverages'),
('PEP', 'PepsiCo Inc.', 'Consumer Defensive', 'Beverages'),
('WMT', 'Walmart Inc.', 'Consumer Defensive', 'Discount Stores'),
('COST', 'Costco Wholesale Corporation', 'Consumer Defensive', 'Discount Stores'),
('PM', 'Philip Morris International Inc.', 'Consumer Defensive', 'Tobacco'),

-- Industrials
('BA', 'The Boeing Company', 'Industrials', 'Aerospace & Defense'),
('CAT', 'Caterpillar Inc.', 'Industrials', 'Farm & Heavy Construction Machinery'),
('MMM', '3M Company', 'Industrials', 'Conglomerates'),
('UNP', 'Union Pacific Corporation', 'Industrials', 'Railroads'),
('UPS', 'United Parcel Service Inc.', 'Industrials', 'Integrated Freight & Logistics'),
('RTX', 'Raytheon Technologies Corporation', 'Industrials', 'Aerospace & Defense'),

-- Energy
('XOM', 'Exxon Mobil Corporation', 'Energy', 'Oil & Gas Integrated'),
('CVX', 'Chevron Corporation', 'Energy', 'Oil & Gas Integrated'),
('COP', 'ConocoPhillips', 'Energy', 'Oil & Gas E&P'),

-- Real Estate
('PLD', 'Prologis Inc.', 'Real Estate', 'REIT - Industrial'),
('AMT', 'American Tower Corporation', 'Real Estate', 'REIT - Specialty'),
('CCI', 'Crown Castle International Corp.', 'Real Estate', 'REIT - Specialty'),

-- Utilities
('NEE', 'NextEra Energy Inc.', 'Utilities', 'Utilities - Regulated Electric'),
('DUK', 'Duke Energy Corporation', 'Utilities', 'Utilities - Regulated Electric'),
('SO', 'The Southern Company', 'Utilities', 'Utilities - Regulated Electric'),

-- Materials
('LIN', 'Linde plc', 'Basic Materials', 'Chemicals'),
('APD', 'Air Products and Chemicals Inc.', 'Basic Materials', 'Chemicals'),
('FCX', 'Freeport-McMoRan Inc.', 'Basic Materials', 'Copper'),

-- Communication Services
('GOOG', 'Alphabet Inc.', 'Technology', 'Internet Services'),
('CHTR', 'Charter Communications Inc.', 'Communication Services', 'Entertainment'),
('TMUS', 'T-Mobile US Inc.', 'Communication Services', 'Telecom Services'),

-- ETFs and Index Funds
('SPY', 'SPDR S&P 500 ETF Trust', 'Financial Services', 'Asset Management'),
('QQQ', 'Invesco QQQ Trust', 'Financial Services', 'Asset Management'),
('VTI', 'Vanguard Total Stock Market ETF', 'Financial Services', 'Asset Management'),
('VOO', 'Vanguard S&P 500 ETF', 'Financial Services', 'Asset Management'),
('IVV', 'iShares Core S&P 500 ETF', 'Financial Services', 'Asset Management'),
('IWM', 'iShares Russell 2000 ETF', 'Financial Services', 'Asset Management')
ON CONFLICT (symbol) DO NOTHING; 