function PostExtract(fields, tables, ctx)
    local zero = ctx:CreateDecimal('0.00')
    local merged = ctx:CreateTable()
    merged:AppendColumn('Subtotal')
    merged:AppendColumn('Tax')
    merged:AppendColumn('Total')
    merged:AppendColumn('TaxPercent')
    tables['MergedVatLineItems'] = merged
    if fields.InvoiceSubtotal then
        if tables.LineItems then
            local items = tables.LineItems
            local taxRates = {}
            for i = 0, items.Length - 1 do
                if #taxRates == 0 and items[i].TaxPercent.Value and items[i].Tax.Value then
                    taxRates[#taxRates + 1] = { rate = items[i].TaxPercent.Value, total = items[i].Tax.Value }
                elseif #taxRates > 0 and items[i].TaxPercent.Value and items[i].Tax.Value then
                    local entryFound = false
                    for j = 1, #taxRates do
                        if taxRates[j].rate == items[i].TaxPercent.Value then
                            taxRates[j].total = taxRates[j].total + items[i].Tax.Value
                            entryFound = true
                            break
                        end
                    end
                    if not entryFound then
                        taxRates[#taxRates + 1] = { rate = items[i].TaxPercent.Value, total = items[i].Tax.Value }
                    end
                end
            end
            if #taxRates > 0 then
                for i=1, #taxRates do
                    if taxRates[i].rate == 21 then
                        local total = fields.InvoiceSubtotal + taxRates[i].total
                        merged:AppendRow()
                        merged[-1].Subtotal = fields.InvoiceSubtotal
                        merged[-1].Tax = taxRates[i].total
                        merged[-1].Total = total
                        merged[-1].TaxPercent = taxRates[i].rate
                    elseif taxRates[i].total ~= zero then
                        local subtotal = taxRates[i].total / (taxRates[i].rate / 100)
                        merged:AppendRow()
                        merged[-1].Subtotal = subtotal:Round(2)
                        merged[-1].Tax = taxRates[i].total
                        merged[-1].Total = (subtotal + taxRates[i].total):Round(2)
                        merged[-1].TaxPercent = taxRates[i].rate
                    elseif taxRates[i].total == zero then
                        local subtotal = fields.InvoiceSubtotal
                        merged:AppendRow()
                        merged[-1].Subtotal = subtotal
                        merged[-1].Tax = zero
                        merged[-1].Total = subtotal
                        merged[-1].TaxPercent = taxRates[i].rate
                    end
                end
            end
        end
    end
end