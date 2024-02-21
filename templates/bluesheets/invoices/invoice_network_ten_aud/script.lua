function Finalize(fields, tables, ctx)
    local yyyy = fields.InvoiceDate.Value.Year or nil
    if tables.LineItems and yyyy then
        local items = tables.LineItems
        for i=items.Length-1, 0, -1 do
            local date = items[i].Date.Text:match('%d+%/%d+')
            if date then
                items[i].Date = ctx:CreateDate(date .. '/' .. yyyy , 'dd/mm/yyyy') or nil
            end
            if not items[i].Total.Value then
                items:RemoveRow(i)
            end
        end
    end
end