function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local items = tables.LineItems
        local lotsCounter = 1
        for i = 0, items.Length - 1 do
            if items[i].Description.Value and items[i].ProductName.Value then
                local itemFound = items[i].Description.Text:match('^%d%d%d%d+%s+(.+)$')
                local isContainDate = items[i].ProductName.Text:match('%d%d%.%d%d.%d+')
                if not fields['ItemName'] then
                    fields['ItemName'] = itemFound and itemFound:gsub('^[%|%s]+', '') or items[i].Description.Text
                end
                if not isContainDate then
                    for code in items[i].ProductName.Text:gmatch('[A-Z]*%d+') do
                        fields['LotNo' .. lotsCounter] = code
                        lotsCounter = lotsCounter + 1
                    end
                else
                    fields['LotNo' .. lotsCounter] = items[i].ProductName.Text
                    lotsCounter = lotsCounter + 1
                end
            end
        end
        tables.LineItems = nil
    end
end