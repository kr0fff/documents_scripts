function Finalize(fields, tables, ctx)
    if not fields.Invoice then
        fields.Invoice = 'na'
    end
    if fields.TreatmentStartDate then
        local yyyy = fields.TreatmentStartDate.Value and fields.TreatmentStartDate.Value.Year or nil
        if yyyy and (tonumber(yyyy) > 2500 or nil) then
            fields.TreatmentStartDate = fields.TreatmentStartDate:AddYears(-543)
        else
            fields.TreatmentStartDate = createDateOnSpecifiedLang(ctx, fields.TreatmentStartDate.Text)
        end
    end
    if tables and tables.LineItems then
        local items = tables.LineItems
        if items[-1].Total.Value then
            fields.AmtClaimList = items[-1].Total.Value
            items:RemoveRow(-1)
        end
    end
end
function createDateOnSpecifiedLang(ctx, field)
    local thaiMonths = { { hrv = 'มกราคม', eng = 'jan' }, { hrv = 'กุมภาพันธ์', eng = 'feb' }, { hrv = 'มีนาคม', eng = 'mar' }, { hrv = 'เมษายน', eng = 'apr' }, { hrv = 'พฤษภาคม', eng = 'may' }, { hrv = 'มิถุนายน', eng = 'jun' }, { hrv = 'กรกฎาคม', eng = 'jul' }, { hrv = 'สิงหาคม', eng = 'aug' }, { hrv = 'กันยายน', eng = 'sep' }, { hrv = 'ตุลาคม', eng = 'oct' }, { hrv = 'พฤศจิกายน', eng = 'nov' }, { hrv = 'ธันวาคม', eng = 'dec' }, { hrv = 'มค', eng = 'jan' }, { hrv = 'กพ', eng = 'feb' }, { hrv = 'มีค', eng = 'mar' }, { hrv = 'เมย', eng = 'apr' }, { hrv = 'พค', eng = 'may' }, { hrv = 'มิย', eng = 'jun' }, { hrv = 'กค', eng = 'jul' }, { hrv = 'สค', eng = 'aug' }, { hrv = 'กย', eng = 'sep' }, { hrv = 'ตค', eng = 'oct' }, { hrv = 'พย', eng = 'nov' }, { hrv = 'ธค', eng = 'dec' } }
    local dd, mon, yyyy = field:gsub('[%s%p]+', ''):match('(%d+)(%D+)(%d%d+)')
    if dd and mon and yyyy then
        if yyyy:match('^%d%d%d$') then
            return nil
        end
        if tonumber(yyyy) < 100 then
            yyyy = '25' .. yyyy
        end
        for _, month in ipairs(thaiMonths) do
            if mon == month['hrv'] then
                mon = month['eng']
            end
        end
        local date = ctx:CreateDate(dd .. mon .. yyyy, 'ddmonyyyy') or nil
        if date then
            return date:AddYears(-543)
        else
            return nil
        end
    else
        return nil
    end
end