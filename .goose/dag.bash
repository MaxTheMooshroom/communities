
declare -A DAG
declare -a DAG_REGISTERED_TRANSFORMS
declare -a DAG_TARGET_STACK

INNER_EXPANSION_REGEX=""
OUTER_EXPANSION_REGEX=""

#  %{}  is an eval that uses an argument name for the currently-scoped target
#       it's an "inner" expansion. As in, it doesn't reference objects outside the target

# %%{}  is an eval that uses the environment
#       it's an "outer" expansion. As in, it references objects outside the target

# transforms "dependency1,dependency2->output1,output5"
function transforms () {
    local transformation="$1"
    
    # TODO: validate transformation
    [[ x"${transformation}" == x"" ]] && error "transform cannot be empty!" 255

    local -a parts
    local -a dependencies
    local -a products

    IFS=' ' read -ra parts        <<< "$(echo ${transformation} | sed 's/=>/ /g')"
    IFS=',' read -ra dependencies <<< "${parts[0]}"
    IFS=',' read -ra products     <<< "${parts[1]}"

    for (( i=0; i<${#dependencies[@]}; i++ )); do
        for (( j=0; j<${#products[@]}; j++ )); do
            if [[ x"${dependencies[i]}" == x"${products[j]}" ]]; then
                error "transformation output cannot depend on itself!" 255
            fi
        done
    done

    DAG_REGISTERED_TRANSFORMS+=("${transformation}")
}

# DAG["test"]="%%{input-names}.c,%%{input-names}.h->%%{input-names}.o %%{input-names}.o->%{output-name}"
# DAG["build"]="dependency1,dependency2->output1,output5 dependency3,dependency5->output2"
# DAG["run"]="dependency6"

# function consumes () {
#     return
# }

function var_expansion_inner () {
    return
}

function var_expansion_outer () {
    return
}

function var_expansion () {
    return
}

function dag_process_target_transforms () {
    for transformation in "${DAG_REGISTERED_TRANSFORMS[@]}"; do
        local expanded_transformation="$(var_expansion ${transformation})"
        IFS=' ' read -ra parts        <<< "$(echo ${expanded_transformation} | sed 's/->/ /g')"
        IFS=',' read -ra dependencies <<< "${parts[0]}"
        IFS=',' read -ra products     <<< "${parts[1]}"

        for dependency in "${dependencies[@]}"; do
            for product in "${products[@]}"; do
                DAG[${dependency}]="DAG[${dependency}] ${product}"
            done
        done
    done
}

function dag_export_dot_all () {
    local dotfile="dag.dot"

    {
        echo "digraph DAG {"
        echo "  graph [compound=true];"
        for target in "${!DAG[@]}"; do
            echo "  subgraph cluster_target_${target} {"
            echo "    label = \"${target}\";"

            IFS=' ' read -ra transformations <<< "${DAG[${target}]}"

            for transformation in "${transformations[@]}"; do
                IFS=' ' read -ra parts <<< "$(echo ${transformation} | sed 's/->/ /g')"

                IFS=',' read -ra dependencies <<< "${parts[0]}"
                IFS=',' read -ra products     <<< "${parts[1]}"

                for (( i=0; i<${#dependencies[@]}; i++ )); do
                    for (( j=0; j<${#products[@]}; j++ )); do
                        # comment out lines with a %, as they aren't parsed and processed yet
                        # TODO: parse and process %{} and %%{}
                        [[ x"${dependencies[i]}" == *%* || x"${products[j]}" == *%* ]] && printf "// "
                        echo "    ${dependencies[i]} -> ${products[j]};"
                    done
                done
            done
            echo "  }"
        done
        echo "}"
    } > "${dotfile}" 
}

function dag_export_dot_target () {
    local target="$1"
    local dotfile="dag.dot"

    echo "digraph DAG {" > "${dotfile}"
    {
        echo "  subgraph cluster_target_${target} {"
        echo "    label = \"${target}\";"

        IFS=' ' read -ra transformations <<< "${DAG[${target}]}"

        for transformation in "${transformations[@]}"; do
            IFS=' ' read -ra parts <<< "$(echo ${transformation} | sed 's/->/ /g')"

            IFS=',' read -ra dependencies <<< "${parts[0]}"
            IFS=',' read -ra products     <<< "${parts[1]}"

            for (( i=0; i<${#dependencies[@]}; i++ )); do
                for (( j=0; j<${#products[@]}; j++ )); do
                    # comment out lines with a %, as they aren't parsed and processed yet
                    # TODO: parse and process %{} and %%{}
                    [[ x"${dependencies[i]}" == *%* || x"${products[j]}" == *%* ]] && printf "// "
                    echo "    ${dependencies[i]} -> ${products[j]};"
                done
            done
        done
        echo "  }"
        echo "}"
    } >> "${dotfile}" 
}

# TODO: remove
# dag_export_dot_all

add_flag "-" "export-dag" "export the dag as dag.dot for graphviz (dot -O -Tpng dag.dot)" 10 "target" "string" "the target to generate a dag for (or \"all\" for the entire project's dag)"
function flag_name_export_dag () {
    local target="$1"
    if [[ x"${target}" == x"all" ]]; then
        dag_export_dot_all
    else
        dag_export_dot_target "${target}"
    fi
}
