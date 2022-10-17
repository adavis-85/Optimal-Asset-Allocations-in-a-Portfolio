using Pkg

Pkg.add("CSV")
Pkg.add("DataFrames")

using CSV, DataFrames, Plots

data=CSV.read("C:/Users/User 1/Downloads/testasset.csv",DataFrame)

data=coalesce.(data,0)
data=Matrix(data)

##Every thirty days
every_thirty=collect(1:30:length(data[:,1]))
data=data[every_thirty,:]

function Markowitz(assets,test_nums)
    
    a,b=size(assets)
    rate_ret=zeros(a-1,b)

    for i in 2:a
        rate_ret[i-1,:]=(assets[i,:] .-assets[i-1,:]) ./assets[i-1,:]
    end
        
    ##nan and inf section
    rate_ret=replace!(rate_ret,NaN=>0.0001)
    rate_ret=replace!(rate_ret,Inf=>0.0001)
    
    exp_assets=[sum(rate_ret[:,i])/(a-1) for i in 1:b]
  
    cov_matrix=zeros(b,b)

    for i in 1:b
        for j in 1:b
            cov_matrix[i,j]=sum((rate_ret[:,i] .-exp_assets[i]) .*(rate_ret[:,j] .-exp_assets[j]))/(a-1)
        end
    end

    returns=[]
    risks=[]
    all_weights=[]
    sharpe_score=[]
    
    ##30 day risk-free rate of return.
    r_f=.033
    
    for i in 1:test_nums
        weights=rand(b)
        weights=weights ./sum(weights)
        ret=sum(weights .*exp_assets)
        ris=sqrt(sum(sum(weights[x]*weights[y]*cov_matrix[x,y] for y in 1:b) for x in 1:b))
        if isnan(ret)==false
            if isnan(ris)==false
                push!(returns,ret)
                push!(risks,ris)
                push!(all_weights,weights)
                push!(sharpe_score,(ret-r_f)/ris)
            end
        end
    end
    
    return returns,risks,all_weights,sharpe_score
end

@time ret,risk,allocations,sharpe=Markowitz(data,20000)

##The data input is in the form:
## 1. The risk or x-axis to be graphed. 
## 2. The reward or y-axis
## 3. The weights of each portfolio found from Markowitz algorithm

function pareto_curve(data)
    
    N=length(data[:,1])
    
    x=[]
    y=[]
    
    ##Array for all possible indices that are bested in each objective
    take_out=[]
    
    for i in 1:N
       for j in 1:N
            ##Checking at each step.  Finds all possible.
            if data[i,1]<data[j,1] && data[i,2]>data[j,2]
                push!(take_out,j)
            end
        end
    end
    
    take_out=unique(take_out)
    keep=[i for i in 1:N if i ∉ take_out]
    
    combine_sets=data[keep,:]
    combine_sets=combine_sets[sortperm(combine_sets[:, 1]), :]
    
    return combine_sets[:,1],combine_sets[:,2],combine_sets[:,3],combine_sets[:,4]
    
end



D=hcat(risk,ret,allocations,sharpe)
@time x,y,totals,fronteir_sharpes=pareto_curve(D)

scatter(risk,ret .*100,label="Portfolios")
plot!(x,y .*100,linewidth=5, thickness_scaling = 1,xlabel="Risk",ylabel="Return",label="Pareto Fronteir",legend=:topleft)

plot(fronteir_sharpes,y .*100,xlabel="Sharpe Score",ylabel="Return in Percent",label="Sharpe vs. Portfolio Return",legend=:topleft)


