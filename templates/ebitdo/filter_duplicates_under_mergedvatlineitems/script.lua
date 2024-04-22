function Finalize(fields, tables, ctx)
    if fields.CustomerName then
        fields.CustomerName = fields.CustomerName.Text:match('^KCHV') or fields.CustomerName.Text
    end
    if tables.MergedAll then
        local zero = ctx:CreateDecimal('0.00')
        local merged = tables.MergedAll
        local items = ctx:CreateTable()
        items:AppendColumn('Subtotal')
        items:AppendColumn('Tax')
        items:AppendColumn('Total')
        items:AppendColumn('TaxPercent')
        tables['MergedVatLineItems'] = items
        for i = 0, merged.Length - 1 do
            if merged[i].TaxPercent.Value and items.Length == 0 then
                items:AppendRow()
                items[-1].Subtotal = merged[i].Subtotal.Value or nil
                items[-1].Tax = merged[i].Tax.Value or nil
                items[-1].Total = merged[i].Subtotal.Value and merged[i].Tax.Value and merged[i].Subtotal.Value + merged[i].Tax.Value or nil
                items[-1].TaxPercent = merged[i].TaxPercent.Value
            end
            if not fields.VatTariff and merged[i].TaxPercent.Value and merged[i].TaxPercent.Value ~= zero then
                fields.VatTariff = merged[i].TaxPercent.Value
            end
            if items.Length > 0 and merged[i].TaxPercent.Value then
                local found
                for j = 0, items.Length - 1 do
                    if merged[i].TaxPercent.Value == items[j].TaxPercent.Value then
                        found = true
                        break
                    end
                end
                if not found then
                    items:AppendRow()
                    items[-1].Subtotal = merged[i].Subtotal.Value or nil
                    items[-1].Tax = merged[i].Tax.Value or nil
                    items[-1].Total = merged[i].Subtotal.Value and merged[i].Tax.Value and merged[i].Subtotal.Value + merged[i].Tax.Value or nil
                    items[-1].TaxPercent = merged[i].TaxPercent.Value
                end
            end
        end
        tables.MergedAll = nil
    end
end