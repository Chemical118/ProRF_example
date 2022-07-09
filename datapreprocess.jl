using ProRF, Printf

folder_vector = Vector{String}(["DsReds", "eqFP578s", "CSs"])

for name in folder_vector
    loc = "Data/" * name
    Find, Lind = data_preprocess_index(loc * "/DPP/alnrawdata.fasta")
    @printf "%s : %d %d\n" name Find Lind

    data_preprocess_fill(Find, Lind,
                         loc * "/DPP/alnrawdata.fasta",
                         loc * "/DPP/tree.nwk",
                         loc * "/data.fasta");
    println()
end