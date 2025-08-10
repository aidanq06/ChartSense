-- Seed baseline symbols: NASDAQ-100 constituents (as of mid-2025 approximation) + popular ETFs
-- Safe to re-run; uses ON CONFLICT DO NOTHING.
begin;

insert into public.symbols(symbol, name, exchange, currency, sector, is_baseline) values
-- NASDAQ 100 (partial sample; fill the full set as needed)
('AAPL','Apple Inc','NASDAQ','USD','Technology',true),
('MSFT','Microsoft Corp','NASDAQ','USD','Technology',true),
('NVDA','NVIDIA Corp','NASDAQ','USD','Technology',true),
('AMZN','Amazon.com Inc','NASDAQ','USD','Consumer Discretionary',true),
('META','Meta Platforms Inc','NASDAQ','USD','Technology',true),
('GOOGL','Alphabet Inc Class A','NASDAQ','USD','Technology',true),
('GOOG','Alphabet Inc Class C','NASDAQ','USD','Technology',true),
('TSLA','Tesla Inc','NASDAQ','USD','Consumer Discretionary',true),
('AVGO','Broadcom Inc','NASDAQ','USD','Technology',true),
('COST','Costco Wholesale Corp','NASDAQ','USD','Consumer Staples',true),
('PEP','PepsiCo Inc','NASDAQ','USD','Consumer Staples',true),
('ADBE','Adobe Inc','NASDAQ','USD','Technology',true),
('NFLX','Netflix Inc','NASDAQ','USD','Communication Services',true),
('AMD','Advanced Micro Devices Inc','NASDAQ','USD','Technology',true),
('LIN','Linde plc','NYSE','USD','Materials',true),
('CSCO','Cisco Systems Inc','NASDAQ','USD','Technology',true),
('TMUS','T-Mobile US Inc','NASDAQ','USD','Communication Services',true),
('TXN','Texas Instruments Inc','NASDAQ','USD','Technology',true),
('QCOM','QUALCOMM Inc','NASDAQ','USD','Technology',true),
('AMAT','Applied Materials Inc','NASDAQ','USD','Technology',true),
('INTU','Intuit Inc','NASDAQ','USD','Technology',true),
('BKNG','Booking Holdings Inc','NASDAQ','USD','Consumer Discretionary',true),
('ABNB','Airbnb Inc','NASDAQ','USD','Consumer Discretionary',true),
('PDD','PDD Holdings Inc','NASDAQ','USD','Consumer Discretionary',true),
('SBUX','Starbucks Corp','NASDAQ','USD','Consumer Discretionary',true),
('INTC','Intel Corp','NASDAQ','USD','Technology',true),
('ADI','Analog Devices Inc','NASDAQ','USD','Technology',true),
('MDLZ','Mondelez International Inc','NASDAQ','USD','Consumer Staples',true),
('VRTX','Vertex Pharmaceuticals Inc','NASDAQ','USD','Health Care',true),
('MRVL','Marvell Technology Inc','NASDAQ','USD','Technology',true),
('REGN','Regeneron Pharmaceuticals Inc','NASDAQ','USD','Health Care',true),
('PANW','Palo Alto Networks Inc','NASDAQ','USD','Technology',true),
('ADP','Automatic Data Processing Inc','NASDAQ','USD','Technology',true),
('ISRG','Intuitive Surgical Inc','NASDAQ','USD','Health Care',true),
('HON','Honeywell International Inc','NASDAQ','USD','Industrials',true),
('LRCX','Lam Research Corp','NASDAQ','USD','Technology',true),
('PYPL','PayPal Holdings Inc','NASDAQ','USD','Technology',true),
('MU','Micron Technology Inc','NASDAQ','USD','Technology',true),
('GILD','Gilead Sciences Inc','NASDAQ','USD','Health Care',true),
('AMGN','Amgen Inc','NASDAQ','USD','Health Care',true),
('SNPS','Synopsys Inc','NASDAQ','USD','Technology',true),
('KLAC','KLA Corp','NASDAQ','USD','Technology',true),
('CRWD','CrowdStrike Holdings Inc','NASDAQ','USD','Technology',true),
('MELI','MercadoLibre Inc','NASDAQ','USD','Consumer Discretionary',true),
('CSX','CSX Corp','NASDAQ','USD','Industrials',true),
('LULU','Lululemon Athletica Inc','NASDAQ','USD','Consumer Discretionary',true),
('AEP','American Electric Power Co Inc','NASDAQ','USD','Utilities',true),
('MAR','Marriott International Inc','NASDAQ','USD','Consumer Discretionary',true),
('FTNT','Fortinet Inc','NASDAQ','USD','Technology',true),
('ODFL','Old Dominion Freight Line Inc','NASDAQ','USD','Industrials',true),
('MNST','Monster Beverage Corp','NASDAQ','USD','Consumer Staples',true),
('KDP','Keurig Dr Pepper Inc','NASDAQ','USD','Consumer Staples',true),
('VRTX','Vertex Pharmaceuticals Inc','NASDAQ','USD','Health Care',true),
('ADSK','Autodesk Inc','NASDAQ','USD','Technology',true),
('NXPI','NXP Semiconductors NV','NASDAQ','USD','Technology',true),
('PAYX','Paychex Inc','NASDAQ','USD','Industrials',true),
('CDNS','Cadence Design Systems Inc','NASDAQ','USD','Technology',true),
('ORLY','O'Reilly Automotive Inc','NASDAQ','USD','Consumer Discretionary',true),
('ROST','Ross Stores Inc','NASDAQ','USD','Consumer Discretionary',true),
('CHTR','Charter Communications Inc','NASDAQ','USD','Communication Services',true),
('CRWD','CrowdStrike Holdings Inc','NASDAQ','USD','Technology',true)
on conflict (symbol) do nothing;

-- Popular ETFs
insert into public.symbols(symbol, name, exchange, currency, sector, is_baseline) values
('SPY','SPDR S&P 500 ETF','NYSEARCA','USD','ETF',true),
('QQQ','Invesco QQQ Trust','NASDAQ','USD','ETF',true),
('VTI','Vanguard Total Stock Market ETF','NYSEARCA','USD','ETF',true),
('VOO','Vanguard S&P 500 ETF','NYSEARCA','USD','ETF',true),
('IWM','iShares Russell 2000 ETF','NYSEARCA','USD','ETF',true),
('ARKK','ARK Innovation ETF','NYSEARCA','USD','ETF',true)
on conflict (symbol) do nothing;

commit;


