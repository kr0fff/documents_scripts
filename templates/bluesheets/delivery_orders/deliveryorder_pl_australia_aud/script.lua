function PostExtract(fields, tables, ctx)
    if fields._Anchor0 and fields._GrossWeight and fields._Volume and fields._Item and fields.InvoiceDate then
        local text = ctx['text']
        text = text:GetArea(
                text.BBox.Left,
                fields._Anchor0.BBox.Bottom,
                text.BBox.Right,
                text.BBox.Bottom
        )
        if text.Length > 0 then
            local strSum = ''
            for i = 0, text.Length - 1 do
                strSum = strSum .. text[i]:ToString()
                if text[i]:ToString():match('Marks%s+&%s+Nos') then
                    break
                end
                if i < text.Length - 1 then
                    strSum = strSum .. ' '
                end
            end
            local qty, uom = strSum:match('^%s*(%d+)%s+([A-Z]+)')
            if qty and uom then
                local items = ctx:CreateTable()
                items:AppendColumn('ItemNo', 'Item No.')
                items:AppendColumn('Description')
                items:AppendColumn('Qty', 'QTY')
                items:AppendColumn('UOM')
                items:AppendColumn('GrossWeight', 'Gross Weight')
                items:AppendColumn('Volume')
                items:AppendColumn('Date', 'Arrival Date')
                items:AppendColumn('Total')
                tables['LineItems'] = items
                items:AppendRow()
                items[-1].ItemNo = fields._Item.Text
                items[-1].Description = strSum
                items[-1].Qty = qty
                items[-1].UOM = uom
                items[-1].GrossWeight = fields._GrossWeight
                items[-1].Volume = fields._Volume
                items[-1].Date = fields.InvoiceDate
                items[-1].Total = ctx:CreateDecimal('0.00')
            end
        end
    end
end
function Finalize(fields, tables, ctx)
    if not fields.InvoiceTotal then
        fields.InvoiceTotal = ctx:CreateDecimal('0.00')
    end
end