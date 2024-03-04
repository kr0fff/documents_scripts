s = "AU Upholstered Bed V3 - Silver Fox - Queen - Box 2 - \"FSC MIXED\" and \"Certi Pur\" AU Upholstered Bed V3 - Silver Fox - Queen - Box 3 - \"FSC MIXED\" and \"Certi Pur\" AU Upholstered Bed V3 - Silver Fox - Queen - Box 4 - \"FSC MIXED\" and \"Certi Pur\" | AU Upholstered Bed V3 - Silver Fox - King - Box 1 - \"FSC MIXED\" and \"Certi Pur\""
local spaces = s:gsub('%S+', '')
if string.len(spaces) > 1 then
    local heading = s:match('^([A-Za-z]+%s[A-Za-z]+)')
    --[[for line in string.gmatch(s, '(.+)' .. heading  ) do
        print(line)
    end]]
    for line in string.gmatch(s, heading  ) do
        print(line)
    end
end
