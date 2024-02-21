function PostExtract(fields, tables, ctx)
    local items = tables.LineItems
    items:InsertColumnAt("Qty", "SizeNumeric", "SIZE")
    items:InsertColumnAt("Qty", "Uom", "UOM")

    for i = 0, items.Length - 1 do
        if items[i].Description.Value then

            local matchOz = string.lower(items[i].Description.Text):match("([%d%.]+)%s*oz")
            local matchKeg = string.lower(items[i].Description.Text):match("([%d%/]+)%s*keg")
            local matchMl = string.lower(items[i].Description.Text):match("(%d+)%s*ml")
            local matchBbl = string.lower(items[i].Description.Text):match("(%d+%/%d+)%s*bbl")
            local matchLitres = string.lower(items[i].Description.Text):match("(%d+)%s*l")
            if matchOz then
                items[i].SizeNumeric = matchOz
                items[i].Uom = 'OZ'
            end
            if matchKeg then
                items[i].SizeNumeric = matchKeg
                items[i].Uom = 'KEG'
            end
            if matchMl then
                items[i].SizeNumeric = matchMl
                items[i].Uom = 'ML'
            end
            if matchBbl then
                items[i].SizeNumeric = matchBbl
                items[i].Uom = 'BBL'
            end
            if matchLitres then
                items[i].SizeNumeric = matchLitres
                items[i].Uom = 'L'
            end
        end
    end
    for i = items.Length - 1, 0, -1 do
        if not items[i].Total.Value then items:RemoveRow(i) end
    end
end
