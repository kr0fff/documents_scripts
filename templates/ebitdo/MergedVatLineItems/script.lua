function ManualMatch(fields, tables)
    return (fields._SupplierName and fields.InvoiceTotal and 100) or 0
end
function Finalize(fields, tables, ctx)
    --[[if fields.Series and fields.InvoiceNumber then fields.InvoiceNumber = fields.Series.Text .. fields.InvoiceNumber.Text fields.Series = nil end if fields.InvoiceTax and fields.InvoiceTax.Value == 0.00 then fields.VatTariff = 0 end]] if tables.LineItems and tables.LineItems.Length > 0 then
        local items = tables.LineItems
        local merged = ctx:CreateTable()
        merged:AppendColumn('Subtotal')
        merged:AppendColumn('Tax')
        merged:AppendColumn('Total')
        merged:AppendColumn('TaxPercent')
        tables['MergedVatLineItems'] = merged
        for i = 0, items.Length - 1 do
            if items[i].Total.Value then
                local subtotal = items[i].Total.Value or nil
                local tax = items[i].Tax.Value or ctx:CreateDecimal('0.00')
                local total = items[i].Total.Value and tax and items[i].Total.Value + tax or nil
                local taxPercent = subtotal and subtotal > 0 and tax and tax / subtotal or nil
                if subtotal and tax and total and taxPercent then
                    merged:AppendRow()
                    merged[-1].Subtotal = subtotal
                    merged[-1].Tax = tax
                    merged[-1].Total = total
                    merged[-1].TaxPercent = taxPercent:Round(2)
                end
            end
        end
    end --[[ SplitSeriesNumber --]] if fields.SeriesNumber then
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