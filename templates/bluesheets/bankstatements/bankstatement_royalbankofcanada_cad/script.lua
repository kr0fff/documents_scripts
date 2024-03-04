function PostExtract(fields, tables, ctx)
    if fields._Anchor0 then
        local text = ctx['text']
        text = text:GetArea(
                fields._Anchor0.BBox.Right,
                fields._Anchor0.BBox.Top,
                text.BBox.Right,
                fields._Anchor0.BBox.Bottom
        )
        if text.Length > 0 then
            fields.BankAccountNumber = text[0]:ToString():gsub('%s+', ''):match('[%d%-]+')
        end
    end
end
function Finalize(fields, tables, ctx)

    local months = { { num = 1, eng = 'jan' }, { num = 2, eng = 'feb' }, { num = 3, eng = 'mar' },
                     { num = 4, eng = 'apr' }, { num = 5, eng = 'may' }, { num = 6, eng = 'jun' },
                     { num = 7, eng = 'jul' }, { num = 8, eng = 'aug' }, { num = 9, eng = 'sep' },
                     { num = 10, eng = 'oct' }, { num = 11, eng = 'nov' }, { num = 12, eng = 'dec' } }
    if tables.LineItems then
        local items = tables.LineItems
        local fromMonth = fields.DateFrom and fields.DateFrom.Value.Month or nil
        local toMonth = fields.DateTo and fields.DateTo.Value.Month or nil
        local fromYear = fields.DateFrom and fields.DateFrom.Value.Year or nil
        local toYear = fields.DateTo and fields.DateTo.Value.Year or nil
        for i=items.Length-1,0,-1 do
            if items[i].Date.Value then
                local year
                local dd, mon = items[i].Date.Text:match('(%d+)%s+([A-Z][a-z][a-z])')
                if dd and mon then
                    for _, month in ipairs(months) do
                        if string.lower(mon) == month['eng'] then
                            mon = month['num']
                            if fromMonth and tonumber(mon) == fromMonth then
                                year = fromYear
                            end
                            if toMonth and tonumber(mon) == toMonth then
                                year = toYear
                            end
                        end
                    end
                end
                if dd and mon and year then
                    items[i].Date = ctx:CreateDate(dd .. '/' .. mon .. '/' .. year, 'dd/mm/yyyy') or nil
                end
            end
            if items[i].Description.Text:match('Opening%s+balance') then
                items:RemoveRow(i)
            end
        end
    end
end