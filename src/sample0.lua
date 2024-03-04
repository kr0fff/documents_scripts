function ManualMatch(fields, tables)
    return (fields._Anchor0 and fields._Anchor1 and fields._Anchor2 and 100) or 0
end
function Finalize(fields, tables, ctx)
    if fields.InvoiceNumber then
        fields.InvoiceNumber = fields.InvoiceNumber.Text:gsub('%s+', '')
    end
    if tables.LineItems then
        local items = tables.LineItems
        local merged = ctx:CreateTable()
        merged:AppendColumn('Subtotal')
        merged:AppendColumn('Tax')
        merged:AppendColumn('Total')
        merged:AppendColumn('TaxPercent')
        tables['MergedVatLineItems'] = merged
        local totalRate9 = {subtotal = ctx:CreateDecimal('0.00'), tax = ctx:CreateDecimal('0.00'), total = ctx:CreateDecimal('0.00')}
        local totalRate21 = {subtotal = ctx:CreateDecimal('0.00'), tax = ctx:CreateDecimal('0.00'), total = ctx:CreateDecimal('0.00')}
        local totalRate0 = {subtotal = ctx:CreateDecimal('0.00'), total = ctx:CreateDecimal('0.00')}
        local tax9 = fields.Tax9 or nil
        local tariff9 = fields.Tariff9 or nil
        local tax21 = fields.Tax21 or nil
        local tariff21 = fields.Tariff21 or nil
        for i = 0, items.Length - 1 do
            if tax9 and tariff9 and items[i].TaxPercent.Value and fields.Tariff9.Text == items[i].TaxPercent.Text then
                totalRate9.subtotal = items[i].UnitPriceExTax.Value and totalRate9.subtotal + items[i].UnitPriceExTax.Value or totalRate9.subtotal
                totalRate9.tax = items[i].Tax.Value and totalRate9.tax + items[i].Tax.Value or totalRate9.tax
                totalRate9.total = items[i].Total.Value and totalRate9.total + items[i].Total.Value or totalRate9.total
            end
            if tax21 and tariff21 and items[i].TaxPercent.Value and fields.Tariff21.Text == items[i].TaxPercent.Text then
                totalRate21.subtotal = items[i].UnitPriceExTax.Value and totalRate21.subtotal + items[i].UnitPriceExTax.Value or totalRate21.subtotal
                totalRate21.tax = items[i].Tax.Value and totalRate21.tax + items[i].Tax.Value or totalRate21.tax
                totalRate21.total = items[i].Total.Value and totalRate21.total + items[i].Total.Value or totalRate21.total
            end
            if items[i].TaxPercent.Value and items[i].TaxPercent.Text == '0' then
                totalRate0.subtotal = items[i].UnitPriceExTax.Value and totalRate0.subtotal + items[i].UnitPriceExTax.Value or totalRate0.subtotal
                totalRate0.total = items[i].Total.Value and totalRate0.total + items[i].Total.Value or totalRate0.total
            end
        end
        if tax9 and totalRate9.subtotal > 0 and totalRate9.tax > 0 and totalRate9.total > 0 then
            merged:AppendRow()
            merged[-1].Subtotal = totalRate9.subtotal
            merged[-1].Tax = totalRate9.tax
            merged[-1].Total = totalRate9.total
            merged[-1].TaxPercent = fields.Tariff9
            fields.Tariff9 = nil
            fields.Tax9 = nil
        end
        if tax21 and totalRate21.subtotal > 0 and totalRate21.tax > 0 and totalRate21.total > 0 then
            merged:AppendRow()
            merged[-1].Subtotal = totalRate21.subtotal
            merged[-1].Tax = totalRate21.tax
            merged[-1].Total = totalRate21.total
            merged[-1].TaxPercent = fields.Tariff21
            fields.VatTariff = fields.Tariff21
            fields.Tariff21 = nil
            fields.Tax21 = nil
        end
        if totalRate0.subtotal > 0 and totalRate0.total > 0 then
            merged:AppendRow()
            merged[-1].Subtotal = totalRate0.subtotal
            merged[-1].Total = totalRate0.total
            merged[-1].Tax = ctx:CreateDecimal('0.00')
            merged[-1].TaxPercent = ctx:CreateDecimal('0.00')
        end
    end
end