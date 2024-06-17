function PostExtract(fields, tables, ctx)
    local items = ctx:CreateTable()
    items:AppendColumn('Description')
    items:AppendColumn('Qty')
    items:AppendColumn('UOM')
    items:AppendColumn('UnitPriceIncTax', 'Unit Price')
    items:AppendColumn('TaxPercent', 'VAT %')
    items:AppendColumn('Tax', 'VAT')
    items:AppendColumn('Total')
    tables['LineItems'] = items
    if fields.VatTariff then
        fields.VatTariff = CastToDecimal(fields.VatTariff.Text:gsub('%%', ''), ctx)
    end
    if fields._CustomerAnchor then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = text.BBox.Left
        local y0 = fields._CustomerAnchor.BBox.Bottom + h * 3
        local x1 = text.BBox.Right
        local y1 = fields._CustomerAnchor.BBox.Bottom + h * 7
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 1 then
            for i = 1, text.Length - 1 do
                local code, taxId = text[i]:ToString():match('(%d+)%s+([A-Z][A-Z]%d+)')
                local onlyCode = text[i]:ToString():match('^%d+$')
                if code and taxId then
                    fields.CustomerCode = code
                    fields.CustomerTaxId = taxId
                    fields.CustomerName = text[i - 1]:ToString()
                    break
                elseif onlyCode and onlyCode:len() >= 9 then
                    fields.CustomerCode = onlyCode
                    fields.CustomerName = text[i - 1]:ToString()
                    break
                end
            end
        end
    end
    if fields._Anchor0 and fields._Anchor1 then
        local text = ctx['text']
        text = text:GetArea(text.BBox.Left, fields._Anchor0.BBox.Bottom, text.BBox.Right, fields._Anchor1.BBox.Top)
        if text.Length > 0 then
            local strSum = ''
            local stationCheck
            local unitCheck
            local item = { Description = nil, Qty = nil, UOM = nil, UnitPriceIncTax = nil, Tax = nil, TaxPercent = nil, Total = nil }
            for i = 0, text.Length - 1 do
                local line = text[i]:ToString()
                strSum = strSum .. ' || ' .. line
                if line and string.len(line) > 0 then
                    local item_v1, qty_v1, uom_v1, total_v1 = line:match('([A-z%d%s%p]+)%s+([%d%,%.]+%d%d)%s+([A-z%p]+)%s+([%d%,%.]+%d%d+)%s+[AC]')
                    local unitPrice_v1 = line:match('Kolon.+%s*Nr%d+%s+([%d%,%.]+%d%d+)%s+EUR')
                    local prevIsDiscount = i > 0 and text[i - 1]:ToString():match('Nuolaida') or nil
                    local discount = prevIsDiscount and line:match('([%-%d%,]+%d%d+)%s+[AC]') or nil
                    if discount then
                        discount = RoundValue(discount, ctx)
                        items:AppendRow()
                        items[-1].Description = 'Nuolaida'
                        items[-1].Qty = ctx:CreateDecimal('1.00') or nil
                        items[-1].UnitPriceIncTax = discount or nil
                        items[-1].TaxPercent = ctx:CreateDecimal('0.00')
                        items[-1].Tax = ctx:CreateDecimal('0.00')
                        items[-1].Total = discount or nil
                    end
                    if item_v1 and qty_v1 and uom_v1 and total_v1 then
                        unitCheck = true
                        item.Description = item_v1
                        item.Qty = RoundValue(qty_v1, ctx)
                        item.UOM = uom_v1
                        item.Total = RoundValue(total_v1, ctx)
                    elseif unitPrice_v1 then
                        stationCheck = true
                        item.UnitPriceIncTax = RoundValue(unitPrice_v1, ctx)
                    end
                    if stationCheck and unitCheck then
                        items:AppendRow()
                        local subtotal = item.Total and fields.VatTariff and item.Total / (1 + fields.VatTariff.Value / 100) or nil
                        local tax = subtotal and fields.VatTariff and subtotal * (fields.VatTariff.Value / 100) or nil
                        items[-1].Description = item.Description
                        items[-1].Qty = item.Qty
                        items[-1].UOM = item.UOM
                        items[-1].UnitPriceIncTax = item.UnitPriceIncTax
                        items[-1].Tax = tax and tax:Round(2) or nil
                        items[-1].TaxPercent = fields.VatTariff or nil
                        items[-1].Total = item.Total
                        for it in pairs(item) do
                            item[it] = nil
                        end
                        stationCheck = nil
                        unitCheck = nil
                    end
                end
            end --[[fields.ItemSummary = strSum]]
        end
    end
end
function RoundValue(str, ctx)
    local decimal = CastToDecimal(str, ctx)
    return decimal and decimal:Round(2) or nil
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
    end --[[ SplitSeriesNumber --]]
end