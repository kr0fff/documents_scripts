function CastToDecimal(str, ctx)
    local decimal = str:gsub('%.+', ''):match('%d+')
    return ctx:CreateDecimal(decimal) or nil
end
function PostExtract(fields, tables, ctx)
    if fields._InvoiceTotal then
        fields.InvoiceTotal = CastToDecimal(fields._InvoiceTotal.Text, ctx)
    end
    if fields._Anchor0 and fields.InvoiceNumber then
        local text = ctx['text']
        text = text:GetArea(
                fields._Anchor0.BBox.Right,
                fields.InvoiceNumber.BBox.Bottom,
                text.BBox.Right,
                fields._Anchor0.BBox.Top
        )
        if text.Length > 0 then
            fields.CustomerName = text[0]:ToString():gsub('^[%s%:]+', '')
        end
    end
    if fields._InvoiceDate then
        local dd, mon, yyyy = fields._InvoiceDate.Text:match('(%d+)%s*([%a%p]+)%s*(%d%d+)')
        local months = { { ind = 'januari', eng = 'jan' }, { ind = 'februari', eng = 'feb' }, { ind = 'maret', eng = 'mar' }, { ind = 'april', eng = 'apr' }, { ind = 'mei', eng = 'may' }, { ind = 'juni', eng = 'jun' }, { ind = 'juli', eng = 'jul' }, { ind = 'agustus', eng = 'aug' }, { ind = 'september', eng = 'sep' }, { ind = 'oktober', eng = 'oct' }, { ind = 'november', eng = 'nov' }, { ind = 'desember', eng = 'dec' } }
        for _, month in ipairs(months) do
            if mon and string.lower(mon) == month['ind'] then
                mon = month['eng']
            end
        end
        if dd and mon and yyyy then
            fields.InvoiceDate = ctx:CreateDate(dd .. mon .. yyyy, 'ddmonyyyy') or ctx:CreateDate(dd .. mon .. yyyy, 'ddmonyy') or nil
        end
    end
end
function Finalize(fields, tables, ctx)
    if tables.LineItems then
        local extraTopLineIndex
        local items = tables.LineItems
        local strSum = ''
        for i = items.Length - 1, 0, -1 do
            if items[i].UnitPrice.Value then
                items[i].UnitPrice = CastToDecimal(items[i].UnitPrice.Text, ctx)
            end
            if items[i].Total.Value then
                items[i].Total = CastToDecimal(items[i].Total.Text, ctx)
            end
            if i > 0 and i < items.Length - 1 and not items[i].Description.Value then
                local prev = items[i - 1].Description.Value and not items[i - 1].Total.Value and items[i - 1].Description.Text or ''
                local next = items[i + 1].Description.Value and not items[i + 1].Total.Value and ' ' .. items[i + 1].Description.Text or ''
                items[i].Description = prev .. next
                extraTopLineIndex = i - 1
                items:RemoveRow(i + 1)
            end
            if extraTopLineIndex and i == extraTopLineIndex then
                extraTopLineIndex = nil
                items:RemoveRow(i)
            end
        end
        for i = items.Length - 1, 0, -1 do
            if not items[i].Total.Value then
                strSum = items[i].Description.Value and (items[i].Description.Text .. ' ' .. strSum) or strSum
                items:RemoveRow(i)
            else
                items[i].Description = items[i].Description.Value and (items[i].Description.Text .. ' ' .. strSum) or strSum
                strSum = ''
            end
        end
        if fields.Discount then
            local decimal = CastToDecimal(fields.Discount.Text, ctx)
            items:AppendRow()
            items[-1].Description = 'Discount'
            items[-1].Qty = 1
            items[-1].UnitPrice = decimal and decimal * -1 or nil
            items[-1].Total = decimal and decimal * -1 or nil
            fields.Discount = nil
        end
    end
end