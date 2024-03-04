local str = 'USD 6,390.25 lumpsum.'
local decimal = str:gsub('%,+', ''):match('%d+%.%d%d')
print(decimal)
