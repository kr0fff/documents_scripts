function PostExtract(fields, tables, ctx)
    if fields.InvoiceTax and not fields.InvoiceTotal then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = fields.InvoiceTax.BBox.Left
        local y0 = fields.InvoiceTax.BBox.Bottom
        local x1 = fields.InvoiceTax.BBox.Right
        local y1 = fields.InvoiceTax.BBox.Bottom + h * 3
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 0 then
            fields.InvoiceTotal = text[0]:ToString()
        end
    end
end
function Finalize(fields, tables, ctx)
    if tables and tables.LineItems then
        local items = tables.LineItems
        for i = items.Length - 1, 0, -1 do
            if not items[i].Total.Value then
                items:RemoveRow(i)
            end
        end
    end
    if fields.CustomerName then
        fields.CustomerName = fields.CustomerName.Text:gsub('^[%s%:]+', '')
    end
end