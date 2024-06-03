function PostExtract(fields, tables, ctx)
    if fields._Anchor0 then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = text.BBox.Left
        local y0 = fields._Anchor0.BBox.Top
        local x1 = fields._Anchor0.BBox.Left
        local y1 = fields._Anchor0.BBox.Bottom + h * 3
        text = text:GetArea(x0, y0, x1, y1)
        local strSum =''
        if text.Length > 0 then
            for i=0, text.Length-1 do
                local barcode = text[i]:ToString():match('[A-Z]+%d+')
                strSum = strSum .. ' | ' .. text[i]:ToString()
                if barcode and string.len(barcode) > 4 then
                    fields.InvoiceNumber = barcode
                    break
                end
            end
            fields.Output = strSum
        end
    end
end
function Finalize(fields, tables, ctx)
    if fields.InvoiceDate and not fields.FromDate then
        fields.FromDate = fields.InvoiceDate
    end
    if tables.LineItems then
        local items = tables.LineItems
        local fromYear = fields.FromDate and fields.FromDate.Value.Year or nil
        local fromMonth = fields.FromDate and fields.FromDate.Value.Month or nil
        local toMonth = fields.ToDate and fields.ToDate.Value.Month or nil
        local toYear = fields.ToDate and fields.ToDate.Value.Year or nil
        for i= items.Length-1, 0, -1 do
            if items[i].Date.Value then
                local dd, mm = items[i].Date.Text:match('(%d+)%p(%d+)')
                if dd and mm and fromMonth and fromYear and toMonth and toYear then
                    local yyyy = tonumber(mm) > tonumber(toMonth) and fromYear or toYear
                    items[i].Date = ctx:CreateDate(dd..mm..yyyy, 'ddmmyyyy') or nil
                end
            end
            if items[i].Total.Value then
                local total = items[i].Total.Text:gsub('[%,%s]+', ''):match('%d+%.%d%d')
                local isNegative = items[i].Total.Text:match('%-')
                items[i].Total = total and isNegative and ctx:CreateDecimal(total) * -1 or ctx:CreateDecimal(total) or nil
            end
            if not items[i].Date.Value then
                items:RemoveRow(i)
            end
        end
    end
end