function PostExtract(fields, tables, ctx)
    if fields._Anchor0 then
        local text = ctx['text']
        local h = text.AvgWordHeight
        text = text:GetArea(fields._Anchor0.BBox.Right, fields._Anchor0.BBox.Top - h * 5, text.BBox.Right, text.BBox.Bottom)
        if text.Length > 0 then
            local str = ''
            for i = 0, text.Length - 1 do
                if string.len(text[i]:ToString()) > 0 then
                    local line = text[i]:ToString()
                    local inlineCustomerName = line:match('^(.+)[%s%p]+%d%d%d%d%d+')
                    fields.CustomerName = inlineCustomerName and inlineCustomerName:gsub('[%.%,]+$', '') or line
                    fields.CustomerCode = line:match('%d%d%d%d%d+$') or nil
                    break
                end
            end
        end
    end
    if fields._SupplierName then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = (text.BBox.Left + text.BBox.Right) / 2
        local y0 = fields._SupplierName.BBox.Top - h * 2
        local x1 = text.BBox.Right
        local y1 = fields._SupplierName.BBox.Top
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 0 then
            fields.CustomerName = text[0]:ToString()
        end
    end
    if fields._TotalAndCurrency then
        local s = fields._TotalAndCurrency.Text:gsub('%,+', '.'):gsub('[%)%(]+', '')
        local total = string.match(s, '%d+.%d+')
        fields.CurrencyCode = string.match(s, '[A-Z][A-Z][A-Z]$')
        fields.InvoiceSubtotal = total and ctx:CreateDecimal(total)
        fields.InvoiceTotal = fields.InvoiceSubtotal
        fields.InvoiceTax = ctx:CreateDecimal('0.00')
        fields.VatTariff = ctx:CreateDecimal('0')
    end
    if tables and tables.LineItems then
        local items = tables.LineItems
        for i = items.Length - 1, 0, -1 do
            local item = items[i]
            if not item.Qty.Value then
                items:RemoveRow(i)
            end
        end
    end
end