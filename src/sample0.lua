function CastToDecimal(str, ctx)
    local decimal = str:gsub('%,+', ''):match('%d+%.%d%d')
    return decimal and ctx:CreateDecimal(decimal) or nil
end
function PostExtract(fields, tables, ctx)
    local total
    local description
    if fields._Anchor2 then
        local text = ctx['text']
        text = text:GetArea(
            text.BBox.Left,
            fields._Anchor2.BBox.Bottom,
            text.BBox.Right,
            text.BBox.Bottom
        )
        if text.Length > 0 then
            local strSum = ''
            for i = 0, text.Length-1 do
                if text[i]:ToString():match('Due%s+Date') then
                    break
                end
                strSum = strSum .. text[i]:ToString()
                if i < text.Length-1 then
                    strSum = strSum .. ' '
                end
            end
            local customer, address = strSum:match('^(.+)%s+([A-Z][a-z]+%s+%d+%,?%s+%d%d%d%d+.+)$')
            fields.CustomerName = customer or strSum
            fields.CustomerAddress = address or strSum
        end
    end
    if fields._Anchor1 then
        local text = ctx['text']
        text = text:GetArea(
                text.BBox.Left,
                fields._Anchor1.BBox.Top,
                text.BBox.Right,
                fields._Anchor1.BBox.Bottom + text.AvgWordHeight
        )
        if text.Length > 0 then
            total = CastToDecimal(text[0]:ToString(), ctx)
            fields.InvoiceTotal = total or nil
        end
    end
    if fields._Anchor0 then
        local text = ctx['text']
        text = text:GetArea(
                text.BBox.Left,
                fields._Anchor0.BBox.Top,
                text.BBox.Right,
                text.BBox.Bottom
        )
        if text.Length > 0 then
            local strSum = ''
            for i=0, text.Length-1 do
                local line = text[i]:ToString()
                if line:match('Amount') then
                    break
                end
                strSum = strSum .. line
                if i < text.Length-1 then
                    strSum = strSum .. ' '
                end
            end
            if string.len(strSum) > 0 then
                description = strSum
            end
        end
    end
    fields.OutputDescription = description
    if description and total then
        local items = ctx:CreateTable()
        items:AppendColumn('Description')
        items:AppendColumn('Total')
        tables['LineItems'] = items
        items:AppendRow()
        items[-1].Description = description
        items[-1].Total = total
    end
end
local a