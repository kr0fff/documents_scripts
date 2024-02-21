function PostExtract(fields, tables, ctx)
    if fields.CustomerCode then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = text.BBox.Left
        local y0 = fields.CustomerCode.BBox.Top - h * 2
        local x1 = text.BBox.Right
        local y1 = fields.CustomerCode.BBox.Bottom - h * 1
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 0 then
            fields.CustomerName = text[0]:ToString()
        end
    end
    if fields._Anchor0 and fields._Anchor1 then
        local text = ctx['text']
        text = text:GetArea(text.BBox.Left, fields._Anchor0.BBox.Bottom, text.BBox.Right, fields._Anchor1.BBox.Top)
        if text.Length > 0 then
            local receiptIndex
            local itemPrice
            local itemQty
            local itemUOM
            local description = ''
            local items = ctx:CreateTable()
            items:AppendColumn('Description')
            items:AppendColumn('Qty')
            items:AppendColumn('UOM')
            items:AppendColumn('UnitPrice')
            items:AppendColumn('Total')
            tables['LineItems'] = items
            local s = ''
            for i = 0, text.Length - 1 do
                local line = text[i]:ToString()
                if not receiptIndex and line:gsub('[%s%#]+', ''):match('^[0-9]+$') then
                    receiptIndex = i
                end
                if receiptIndex and i > receiptIndex then
                    local price, qty, uom = line:match('^([%d%,%.]+)[Xx%s]+([%d%,%.]+)%s+([A-Za-z%d]+)')
                    local total = line:match('(%-?[%d%,%.]+)%s+A$')
                    if price and qty and uom then
                        itemPrice = price
                        itemQty = qty
                        itemUOM = uom
                    end
                    if not price and not qty and not uom and not line:match('Kvitas') then
                        description = description .. ' ' .. line:gsub('%-?[%d%,%.]+%s+A$', '')
                    end
                    if total then
                        items:AppendRow()
                        items[-1].UOM = itemUOM or nil
                        items[-1].UnitPrice = itemPrice and CastToDecimal(itemPrice, ctx) or nil
                        items[-1].Qty = itemQty and CastToDecimal(itemQty, ctx) or nil
                        items[-1].Description = description
                        items[-1].Total = total and CastToDecimal(total, ctx) or nil
                        description = ''
                        itemQty = nil
                        itemPrice = nil
                        itemUOM = nil
                    end
                    if line:match('Nuolaida') then
                        break
                    end
                end
            end
            fields.ItemSummary = s
        end
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('%,+', '.')
    return ctx:CreateDecimal(decimal) or nil
end
function Finalize(fields, tables)
    --[[ SplitSeriesNumber --]] if fields.SeriesNumber then
        local delimiters = { 'nr', 'no', '-', ' ' }
        str = string.lower(fields.SeriesNumber.Text)
        str = string.gsub(str, '[.:,;<>#]+', '')
        str = string.gsub(str, '^%s*(.-)%s*$', '%1')
        local result = nil
        local separator = nil
        local series = ''
        local number = ''
        for i = 1, #delimiters do
            if string.match(str, delimiters[i]) then
                local t = {}
                for str in string.gmatch(str .. delimiters[i], '(.-)' .. delimiters[i]) do
                    t[#t + 1] = str
                end
                result = t
                separator = delimiters[i]
                break
            end
        end
        if not result then
            series, number = string.match(str, '(.-%a)(%d%d%d%d+)')
            if not series and not number then
                number = str
            end
        else
            if not string.match(result[1], '%a') then
                number = str
            else
                series = result[1]
                for i = 2, #result do
                    number = number == '' and number .. result[i] or number .. separator .. result[i]
                end
            end
        end
        series = series or ''
        series = string.gsub(series, '%s+', '')
        series = string.upper(series)
        number = number or ''
        number = string.gsub(number, '%s+', '')
        number = string.upper(number)
        fields.Series = series
        fields.InvoiceNumber = number
        fields.SeriesNumber = nil
    end --[[ SplitSeriesNumber --]]
end