function Finalize(fields, tables, ctx)
    if not fields.InvoiceNumber then
        fields.InvoiceNumber = 'NA'
    end
    if tables.LineItems then
        local items = tables.LineItems
        local zero = ctx:CreateDecimal('0.00')
        local totalFound
        for i = 0, items.Length - 1 do
            local exit = items[i].Description.Text:gsub('%s+', ''):match('^合計%:$')
            if exit then
                totalFound = i
            end
        end
        for i = items.Length - 1, 0, -1 do
            if totalFound and i >= totalFound or items[i].Total.Value and items[i].Total.Value == zero or not items[i].Total.Value then
                items:RemoveRow(i)
            end
        end
        if fields.Visa then
            local decimal = fields.Visa.Text:match('%d+[%.%s]+%d%d$')
            items:AppendRow()
            items[-1].Description = 'Visa'
            items[-1].Total = decimal and ctx:CreateDecimal(decimal) or zero
            fields.Visa = nil
        end
        if fields.Cash then
            local decimal = fields.Cash.Text:match('%d+[%.%s]+%d%d$')
            items:AppendRow()
            items[-1].Description = 'Cash'
            items[-1].Total = decimal and ctx:CreateDecimal(decimal) or zero
            fields.Cash = nil
        end
        if fields.Master then
            local decimal = fields.Master.Text:match('%d+[%.%s]+%d%d$')
            items:AppendRow()
            items[-1].Description = 'Master'
            items[-1].Total = decimal and ctx:CreateDecimal(decimal) or zero
            fields.Master = nil
        end
        if fields.UnionPay then
            local decimal = fields.UnionPay.Text:match('%d+[%.%s]+%d%d$')
            items:AppendRow()
            items[-1].Description = 'Union Pay'
            items[-1].Total = decimal and ctx:CreateDecimal(decimal) or zero
            fields.UnionPay = nil
        end
        if fields.Tips then
            items:AppendRow()
            items[-1].Description = 'Tips'
            items[-1].Total = fields.Tips
            fields.Tips = nil
        end
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('[%,%s]+', ''):match('%d+%.%d%d')
    return ctx:CreateDecimal(decimal) or nil
end