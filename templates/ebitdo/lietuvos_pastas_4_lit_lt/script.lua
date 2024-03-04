function Finalize(fields, tables, ctx)
    if fields.InvoiceSubtotal and fields.InvoiceTax and fields.VatTariff then
        local merged = ctx:CreateTable()
        merged:AppendColumn('Subtotal')
        merged:AppendColumn('Tax')
        merged:AppendColumn('Total')
        merged:AppendColumn('TaxPercent')
        tables['MergedVatLineItems'] = merged
        merged:AppendRow()
        merged[-1].Subtotal = fields.InvoiceSubtotal
        merged[-1].Tax = fields.InvoiceTax
        merged[-1].Total = fields.InvoiceSubtotal + fields.InvoiceTax
        merged[-1].TaxPercent = fields.VatTariff
        if fields.ExcludingTax then
            merged:AppendRow()
            merged[-1].Subtotal = fields.ExcludingTax
            merged[-1].Tax = 0
            merged[-1].Total = fields.ExcludingTax
            merged[-1].TaxPercent = 0
            fields.ExcludingTax = nil
        end
    end
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