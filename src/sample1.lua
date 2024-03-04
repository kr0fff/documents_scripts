function PostExtract(fields, tables, ctx)
    if fields._InvoiceDate then
        local date = fields._InvoiceDate.Text:gsub('%D+', '/'):match('%d%d%d%d%/%d+%/%d+')
        fields.InvoiceDate = ctx:CreateDate(date, 'yyyy/mm/dd') or nil
    end
    if fields._InvoiceDueDate then
        local date = fields._InvoiceDueDate.Text:gsub('%D+', '/'):match('%d%d%d%d%/%d+%/%d+')
        fields.InvoiceDueDate = ctx:CreateDate(date, 'yyyy/mm/dd') or nil
    end
    if fields._CurrencyCode then
        local astarCrypto = fields._CurrencyCode.Text:match('ASTR') or fields._CurrencyCode.Text:match('ASTAR')
        if astarCrypto then
            fields.CurrencyCode = 'ASTAR'
        else
            fields.CurrencyCode = fields._CurrencyCode.Text
        end
    end
end
function Finalize(fields, tables, ctx)
    if not fields.InvoiceNumber then
        fields.InvoiceNumber = 'na'
    end
    if tables.LineItems then
        local items = tables.LineItems
        for i = 0, items.Length - 1 do
            local astarCrypto = items[i].Currency.Text:match('^ASTR$')
            if astarCrypto then
                items[i].Currency = nil
                items[i].Currency = 'ASTAR'
            end
        end
    end
end