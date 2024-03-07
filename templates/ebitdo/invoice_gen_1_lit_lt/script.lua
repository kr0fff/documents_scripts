function PostExtract(fields, tables, ctx)
    if fields._Subtype3 then
        fields.DocumentSubtypeId = 3
    end
    local text = ctx['text']
    local customerLeftBorder = fields.InvoiceDate and fields._Match1 and fields.InvoiceDate.BBox.Left < fields._Match1.BBox.Left and fields.InvoiceDate.BBox.Left or fields._Match1.BBox.Left
    local supplier_text = text:GetArea(text.BBox.Left, fields._Match1.BBox.Bottom, fields._Match1.BBox.Left, fields._Match2.BBox.Top)
    local customer_text = text:GetArea(customerLeftBorder, fields._Match1.BBox.Bottom, text.BBox.Right, fields._Match2.BBox.Top)
    fields.SupplierCode = ExtractPattern(supplier_text, { '!PVM', 'kodas' }, '%d{9,}', true)
    fields.SupplierTaxId = ExtractPattern(supplier_text, { 'PVM', 'kodas' }, '[A-Z]+%d{5,}[A-Z0-9-]*', true)
    fields.CustomerCode = ExtractPattern(customer_text, { '!PVM', 'kodas' }, '%d{9,}', true)
    fields.CustomerTaxId = ExtractPattern(customer_text, { 'PVM', 'kodas' }, '[A-Z]+%d{5,}[A-Z0-9-]*', true)
    for i = 0, supplier_text.Length - 1 do
        local itr = supplier_text[i]:GetIterator()
        fields.SupplierIBAN = itr:NextIBAN()
        if fields.SupplierIBAN then
            break
        end
    end
    for i = 0, customer_text.Length - 1 do
        local itr = customer_text[i]:GetIterator()
        fields.CustomerIBAN = itr:NextIBAN()
        if fields.CustomerIBAN then
            break
        end
    end
end
function Finalize(fields, tables, ctx)
    local zero = ctx:CreateDecimal('0.00')
    if fields.InvoiceTax and fields.InvoiceTax == zero and not fields.VatTariff then
        fields.VatTariff = zero
    end
    if fields.AdditionalTax and tables.LineItems then
        local items = tables.LineItems
        items:AppendRow()
        items[-1].Description = 'PVM tarifas 9%'
        items[-1].Total = fields.AdditionalTax
        fields.AdditionalTax = nil
    end
    if not fields.CustomerName and not fields.SupplierName and fields.AlterSupplier and fields.AlterCustomer then
        fields.SupplierName = fields.AlterSupplier
        fields.CustomerName = fields.AlterCustomer
        fields.AlterCustomer = nil
        fields.AlterSupplier = nil
    end --[[ ExpandTotal --]] if fields.InvoiceTotal and not fields.InvoiceSubtotal and not fields.InvoiceTax and not fields.VatTariff then
        fields.InvoiceSubtotal = fields.InvoiceTotal
        fields.InvoiceTax = 0
        fields.VatTariff = 0
    elseif fields.InvoiceSubtotal and not fields.InvoiceTotal and not fields.InvoiceTax and not fields.VatTariff then
        fields.InvoiceTotal = fields.InvoiceSubtotal
        fields.InvoiceTax = 0
        fields.VatTariff = 0
    elseif fields.InvoiceSubtotal and not fields.InvoiceTotal and fields.InvoiceTax then
        fields.InvoiceTotal = fields.InvoiceSubtotal
        fields.VatTariff = 0
    end --[[ ExpandTotal --]] --[[ SplitSeriesNumber --]] if fields.SeriesNumber then
        local delimiters = { 'nr', 'no', ' ' }
        str = string.lower(fields.SeriesNumber.Text):gsub('ir%s+nr', '')
        str = string.gsub(str, '[.:,;<>#]+', '')
        str = string.gsub(str, '^%s*(.-)%s*$', '%1')
        local result = nil
        local separator = nil
        local series = ''
        local number = ''
        for i = 1, #delimiters do
            if string.match(str, delimiters[i]) then
                local t = {}
                for str in string.gmatch(str .. delimiters[i], '(.-)' .. delimiters[i]) do
                    t[#t + 1] = str
                end
                result = t
                separator = delimiters[i]
                break
            end
        end
        if not result then
            series, number = string.match(str, '(.-%a)(%d%d%d%d+)')
            if not series and not number then
                number = str
            end
        else
            if not string.match(result[1], '%a') then
                number = str
            else
                series = result[1]
                for i = 2, #result do
                    number = number == '' and number .. result[i] or number .. separator .. result[i]
                end
            end
        end
        series = series or ''
        series = string.gsub(series, '%s+', '')
        series = string.upper(series)
        number = number or ''
        number = string.gsub(number, '%s+', '')
        number = string.upper(number)
        fields.Series = series
        fields.InvoiceNumber = number
    end --[[ SplitSeriesNumber --]]
end
function ExtractPattern(text, prefix, pattern, fuzzy)
    for i = 0, text.Length - 1 do
        local itr = text[i]:GetIterator()
        local match = true
        local nextCounter = 0
        for j = 1, #prefix do
            local pfx = prefix[j]
            local inv = false
            if string.sub(prefix[j], 1, 1) == '!' then
                pfx = string.sub(pfx, 2)
                inv = true
            end
            local next = fuzzy and itr:NextLiteral(pfx, true) or itr:NextRegex(pfx)
            if next then
                nextCounter = nextCounter + 1
            end
            if (inv and next) or (not inv and not next) then
                match = false
                break
            end
        end
        local value = match and itr:NextRegex(pattern) or nextCounter == 0 and itr:NextRegex(pattern) or nil
        if value then
            return value
        end
    end
    return nil
end