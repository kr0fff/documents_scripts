function PostExtract(fields, tables, ctx)
    if fields.Period and fields.Period.Text then
        local dd, mon, yyyy = fields.Period.Text:match('(%d+)%s*([%a%p]+)%s*(%d%d)')
        local months =
        {{hrv = 'ม.ค.', eng = 'jan'}, {hrv = 'ก.พ.', eng = 'feb'}, {hrv = 'มี.ค.', eng = 'mar'},
         {hrv = 'เม.ย.', eng = 'apr'}, {hrv = 'พ.ค.', eng = 'may'}, {hrv = 'มิ.ย.', eng = 'jun'},
         {hrv = 'ก.ค.', eng = 'jul'}, {hrv = 'ส.ค.', eng = 'aug'}, {hrv = 'ก.ย.', eng = 'sep'},
         {hrv = 'ต.ค.', eng = 'oct'}, {hrv = 'พ.ย.', eng = 'nov'}, {hrv = 'ธ.ค.', eng = 'dec'}}
        for _, month in ipairs(months) do
            if mon == month['hrv'] then
                mon = month['eng']
            end
        end
        if dd and mon and yyyy then
            fields.InvoiceDate = ctx:CreateDate(dd .. mon .. yyyy, 'ddmonyyyy')
        end
    end
end
