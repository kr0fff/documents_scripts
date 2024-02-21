function PostExtract(fields, tables, ctx)
    if fields.InvoiceNumber then
        local items
        if not tables.LineItems then
            items = ctx:CreateTable()
            items:AppendColumn('Description')
            items:AppendColumn('Total')
            tables['LineItems'] = items
        else
            items = tables.LineItems
        end
        local text = ctx['text']
        text = text:GetArea(
                text.BBox.Left,
                fields.InvoiceNumber.BBox.Bottom,
                text.BBox.Bottom,
                text.BBox.Right
        )
        if text.Length > 0 then
            for i = 0, text.Length - 1 do
                local description, total = text[i]:ToString():match('^(.+)%s+(%-*[%$%d%,]+%.%d%d)')
                if text[i]:ToString():match('Total') or text[i]:ToString():match('GST') then
                    break
                end
                if description and total then
                    items:AppendRow()
                    items[-1].Description = description
                    items[-1].Total = CastToDecimal(total, ctx)
                end
            end
        end
    end
end
function CastToDecimal(value, ctx)
    local result = value:gsub('[%$,]', ''):match('%-*%d+%.%d%d')
    return ctx:CreateDecimal(result) or nil
end
function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local items = tables.LineItems
        local subtotal = ctx:CreateDecimal('0.00')
        for i = 0, items.Length - 1 do
            if items[i].Total.Value then
                subtotal = subtotal + items[i].Total.Value
            end
        end
        fields.InvoiceSubtotal = subtotal
    end
end