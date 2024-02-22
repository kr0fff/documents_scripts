function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local items = tables.LineItems
        if items.Length > 0 then
            local total = items[-1].Remarks.Value and items[-1].Remarks.Text:match('Total') and items[-1].Total.Value or nil
            if total then
                items:RemoveRow(items.Length - 1)
                fields.InvoiceTotal = total
            end
        end
    end
end