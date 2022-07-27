using XLSX, DataFrames, Printf, PyCall, Conda

loc_vector = filter(x -> split(x, "\\")[end] == "data.xlsx", reduce(vcat, map(x -> (x[1] * "\\") .* x[3], collect(walkdir(pwd() * "\\Data")))))
data_vector = Vector{Tuple{Vector{String}, String}}()
for eloc in loc_vector
    push!(data_vector, (lowercase.(collect(Set(Vector{String}(filter(x -> !ismissing(x), DataFrame(XLSX.readtable(eloc, "Sheet1", infer_eltypes=true))[!, :Reference]))))), split(eloc, "\\")[end-1]))
end

println(length(data_vector))
println(length(collect(reduce(union, getindex.(data_vector, 1)))))

py"""
def ref_crawl(target):
    from selenium import webdriver
    from fake_useragent import UserAgent
    from selenium.webdriver.chrome.service import Service
    from webdriver_manager.chrome import ChromeDriverManager

    from time import sleep
    ua = UserAgent()
    options = webdriver.ChromeOptions()
    options.add_argument(f'user-agent={ua.random}')
    options.add_argument('headless')
    options.add_argument('window-size=1920x1080')
    options.add_argument("disable-gpu")
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)

    js_get_data = '''return [...document.querySelectorAll('[name="apa"]>div')].map(ele=>{
    var arr = [], loc = []
    for(var i = 0; i < ele.childNodes.length ;i ++) {
        if (ele.childNodes[i] instanceof Text) {
            arr.push(ele.childNodes[i].data)
        } else {
            loc.push(i + 1)
            arr.push(ele.childNodes[i].innerText)
        }
    }
    return [arr, loc]
    })'''

    data_list = []
    main_url = "https://data.doi.or.kr/cite/"
    for ind, tar in enumerate(target):
        driver.get(main_url + tar[16:])
        sleep(5)
        data = driver.execute_script(js_get_data)
        data_list.append(tuple(*data))

    driver.quit()

    return data_list
"""

ref = py"ref_crawl"(collect(reduce(union, getindex.(data_vector, 1))))

ind_dict = Dict{Int, String}()
doi_dict = Dict{String, Int}()
ref_data = deepcopy(ref)
refstr_vector = Vector{String}()
push!(refstr_vector, "\n## Reference\n")
for (ind, (par_vector, ind_vector)) in enumerate(sort(ref_data, by = x -> x[1][1]))
    doi = lowercase(split(par_vector[end], ' ')[end])
    doi_dict[doi] = ind
    ind_dict[ind] = doi

    par_vector[end] = join(split(par_vector[end], ' ')[1:end-1], ' ') * " [" * doi * "]" * "(" * doi * ")"

    for iind in ind_vector
        par_vector[iind] = "_" * par_vector[iind] * "_"
    end
    push!(refstr_vector, @sprintf "\\[%d\\] : %s\n" ind join(par_vector))
end

drefstr_vector = Vector{String}()
push!(drefstr_vector, "## Data Reference\n")
push!(drefstr_vector, "| Dataset | Reference |")
push!(drefstr_vector, "| --- | --- |")
for (ref_vector, data_name) in sort(data_vector, by = x -> x[2])
    ind_vector = sort(map(x -> doi_dict[x], collect(ref_vector)))
    indstr_vector = map(x -> string(@sprintf "\\[%d\\]" x), ind_vector)

    push!(drefstr_vector, @sprintf "| %s | %s |" data_name join(indstr_vector, ", "))
end

open("Reference.txt","w") do io
    println(io, join(drefstr_vector, '\n'))
    println(io, join(refstr_vector, '\n'))
end
