function PostExtract(fields, tables, ctx)
    if fields._ForCustomerName then
        local text = ctx['text']
        local h = text.AvgWordHeight
        local x0 = text.BBox.Left
        local y0 = fields._ForCustomerName.BBox.Top - h * 5
        local x1 = (text.BBox.Left + text.BBox.Right) / 2
        local y1 = fields._ForCustomerName.BBox.Top
        text = text:GetArea(x0, y0, x1, y1)
        if text.Length > 0 then
            fields.CustomerName = text[0]:ToString()
        end
    end
    if tables._Usage then
        local itemsSum = ctx:CreateDecimal('0.00')
        local usage = tables._Usage
        if usage.Length > 0 then
            for i=0, usage.Length - 1 do
                local item = usage[i]
                if item.Total.Value then
                    itemsSum = itemsSum + item.Total.Value
                end
            end
            fields.Usage = itemsSum
        end
    end
end
function Finalize(fields, tables, ctx)
    if fields.InvoiceNumber then
        local pairs = {
            {account = '8941142484' , unit = 'SG_SIN_150CAN'},
            {account = '8939998061' , unit = 'SG_SIN_PG-95_18-09'},
            {account = '8940296364' , unit = 'SG_SIN_URB-01_30-03'},
            {account = '8931836764' , unit = 'SG_SIN_TS-6_18-18'},
            {account = '8940194254' , unit = 'SG_SIN_TS-6_50-18'},
            {account = '8940491726' , unit = 'SG_SIN_TS-6_02-18'},
            {account = '8940499679' , unit = 'SG_SIN_TS-2_40-06'},
            {account = '8941765532' , unit = 'SG_SIN_TS-2_57-06'},
            {account = '8941892849' , unit = 'SG_SIN_TS-6_40-22'},
            {account = '8941758891' , unit = 'SG_SIN_TS-2_14-08'},
            {account = '8941601364' , unit = 'SG_SIN_3+5YSS_02-A_03'},
            {account = '8941601372' , unit = 'SG_SIN_3+5YSS_03-B_03'},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
            {account = '' , unit = ''},
        }
        local unitId = fields.InvoiceNumber.Text
        for _, number in ipairs(ctx['numbers']) do
        end
    end
    if fields.InvoiceTotal and fields.InvoiceTotal < 0 then
        fields.DocumentType = 'credit_note'
    end
end