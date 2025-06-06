#!/bin/bash

print_color() {
    printf "$1\n"
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIMEOUT_NORMAL=25
TIMEOUT_VALGRIND=60

if [ $# -eq 1 ]; then
    print_color "${YELLOW}⚠️  Ce script détecte automatiquement votre projet philosophers${NC}"
    print_color "${BLUE}ℹ️  Aucun argument nécessaire, il trouve ./philo tout seul${NC}"
    print_color ""
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$PARENT_DIR/philo" ]; then
    print_color "${RED}❌ Erreur: Exécutable philo non trouvé dans $PARENT_DIR${NC}"
    print_color ""
    print_color "${YELLOW}💡 Structure attendue:${NC}"
    print_color "   ${WHITE}votre_repo_philo/${NC}"
    print_color "   ${WHITE}├── philo ${CYAN}← Exécutable${NC}"
    print_color "   ${WHITE}├── *.c${NC}"
    print_color "   ${WHITE}├── Makefile${NC}"
    print_color "   ${WHITE}└── philo_testeur/${NC}"
    print_color "   ${WHITE}    └── philo_testeur.sh ${CYAN}← Ce script${NC}"
    print_color ""
    exit 1
fi

PHILO="$PARENT_DIR/philo"

print_color "${CYAN}================================${NC}"
print_color "${WHITE}  🍝      TESTS 42 PHILO    🍝${NC}"
print_color "${CYAN}================================${NC}"
print_color ""

print_color "${GREEN}✅ Projet philosophers détecté${NC}"
print_color "${BLUE}🎯 Exécutable cible: $PHILO${NC}"
print_color ""

if [ ! -x "$PHILO" ]; then
    print_color "${YELLOW}⚠️  Ajout des permissions d'exécution...${NC}"
    chmod +x "$PHILO"
fi

TESTS_PASSED=0
TESTS_FAILED=0
VALGRIND_ERRORS=0
FAILED_TESTS=()

run_single_test() {
    local args="$1"
    local timeout="$2"
    local log_file="$3"
    
    timeout ${timeout}s $PHILO $args > "$log_file" 2>&1
    return $?
}

analyze_test_result() {
    local log_file="$1"
    local expected_death="$2"
    local expected_meals="$3"
    
    local death_count=$(grep -c "died" "$log_file" 2>/dev/null || echo "0")
    local total_lines=$(wc -l < "$log_file" 2>/dev/null || echo "0")
    local exit_code=$4
    
    # Nettoyer death_count
    death_count=$(echo "$death_count" | tr -d '\n\r' | sed 's/[^0-9]//g')
    if [ -z "$death_count" ]; then
        death_count=0
    fi
    
    local result=""
    local status=""
    
    if [ "$expected_death" = "should_die" ]; then
        if [ "$death_count" -gt 0 ]; then
            local death_time=$(grep "died" "$log_file" | head -1 | cut -d' ' -f1)
            local death_philo=$(grep "died" "$log_file" | head -1 | cut -d' ' -f2)
            result="SUCCESS: Mort détectée - Philosophe $death_philo à ${death_time}ms"
            status="PASS"
        else
            result="FAIL: Aucune mort détectée"
            status="FAIL"
        fi
    elif [ "$expected_death" = "check_meals" ] && [ -n "$expected_meals" ]; then
        local meal_count=$(grep -c "is eating" "$log_file" 2>/dev/null || echo "0")
        meal_count=$(echo "$meal_count" | tr -d '\n\r' | sed 's/[^0-9]//g')
        if [ -z "$meal_count" ]; then
            meal_count=0
        fi
        
        if [ "$death_count" -eq 0 ] && [ "$meal_count" -ge "$expected_meals" ]; then
            result="SUCCESS: $meal_count repas comptés (min: $expected_meals)"
            status="PASS"
        elif [ "$death_count" -gt 0 ]; then
            local death_time=$(grep "died" "$log_file" | head -1 | cut -d' ' -f1 2>/dev/null || echo "N/A")
            local death_philo=$(grep "died" "$log_file" | head -1 | cut -d' ' -f2 2>/dev/null || echo "N/A")
            result="FAIL: Mort inattendue - Philosophe $death_philo à ${death_time}ms ($meal_count repas)"
            status="FAIL"
        else
            result="FAIL: Repas insuffisants - $meal_count/$expected_meals"
            status="FAIL"
        fi
    else
        if [ $exit_code -eq 124 ]; then
            result="SUCCESS: Timeout atteint (pas de mort) - $total_lines actions"
            status="PASS"
        elif [ "$death_count" -eq 0 ]; then
            result="SUCCESS: Programme terminé sans mort - $total_lines actions"
            status="PASS"
        else
            local death_time=$(grep "died" "$log_file" | head -1 | cut -d' ' -f1 2>/dev/null || echo "N/A")
            local death_philo=$(grep "died" "$log_file" | head -1 | cut -d' ' -f2 2>/dev/null || echo "N/A")
            result="FAIL: Mort inattendue - Philosophe $death_philo à ${death_time}ms"
            status="FAIL"
        fi
    fi
    
    echo "$status|$result"
}

run_test() {
    local test_name="$1"
    local args="$2"
    local expected_death="$3"
    local timeout="$4"
    local expected_meals="$5"
    
    print_color "${YELLOW}🧪 TEST$test_name${NC}"
    print_color "${CYAN}   Args: $args${NC}"
    print_color "${CYAN}   Timeout: ${timeout}s${NC}"
    
    local attempt=1
    local max_attempts=3
    local pass_count=0
    local fail_count=0
    local results=()
    
    while [ $attempt -le $max_attempts ]; do
        local log_file="/tmp/test_current_${attempt}.log"
        
        if [ $attempt -gt 1 ]; then
            print_color "${BLUE}   🔄 Tentative $attempt/${max_attempts}...${NC}"
        fi
        
        run_single_test "$args" "$timeout" "$log_file"
        local exit_code=$?
        
        local analysis=$(analyze_test_result "$log_file" "$expected_death" "$expected_meals" "$exit_code")
        local status=$(echo "$analysis" | cut -d'|' -f1)
        local result=$(echo "$analysis" | cut -d'|' -f2)
        
        results+=("$result")
        
        if [ "$status" = "PASS" ]; then
            pass_count=$((pass_count + 1))
            print_color "${GREEN}   ✅ $result${NC}"
        else
            fail_count=$((fail_count + 1))
            print_color "${RED}   ❌ $result${NC}"
        fi
        
        # Si on a 2 succès, on peut arrêter
        if [ $pass_count -ge 2 ]; then
            break
        fi
        
        # Si on a 2 échecs et qu'on est à la dernière tentative, on arrête
        if [ $fail_count -ge 2 ] && [ $attempt -eq $max_attempts ]; then
            break
        fi
        
        attempt=$((attempt + 1))
        sleep 0.5  # Petite pause entre les tentatives
    done
    
    # Décision finale basée sur la majorité
    if [ $pass_count -ge 2 ]; then
        print_color "${GREEN}   🎯 RÉSULTAT: SUCCÈS ($pass_count/$attempt réussites)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [ $pass_count -ge 1 ] && [ $attempt -eq 3 ]; then
        print_color "${YELLOW}   ⚠️  RÉSULTAT: INSTABLE ($pass_count/$attempt réussites)${NC}"
        print_color "${YELLOW}      Comportement incohérent détecté${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name: Comportement instable ($pass_count/$attempt réussites)")
    else
        print_color "${RED}   💥 RÉSULTAT: ÉCHEC ($pass_count/$attempt réussites)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        # Prendre le dernier résultat d'échec comme description
        local last_fail=""
        for result in "${results[@]}"; do
            if [[ "$result" == "FAIL:"* ]]; then
                last_fail="$result"
            fi
        done
        FAILED_TESTS+=("$test_name: ${last_fail#FAIL: }")
    fi
    
    print_color ""
    
    # Nettoyer les fichiers de log temporaires
    rm -f /tmp/test_current_*.log
}

run_valgrind_test() {
    local test_name="$1"
    local args="$2"
    local timeout="$3"
    
    print_color "${PURPLE}🔍 VALGRIND: $test_name${NC}"
    print_color "${CYAN}   Args: $args${NC}"
    
    if ! command -v valgrind >/dev/null 2>&1; then
        print_color "${RED}   ❌ Valgrind non installé${NC}"
        return
    fi
    
    timeout ${timeout}s valgrind --tool=helgrind --read-var-info=yes --track-lockorders=yes --history-level=full -s $PHILO $args > /tmp/valgrind_test.log 2>&1
    
    error_summary=$(grep "ERROR SUMMARY:" /tmp/valgrind_test.log | tail -1)
    error_count=$(echo "$error_summary" | grep -o "[0-9]\+ errors" | cut -d' ' -f1 2>/dev/null || echo "0")
    
    data_races=$(grep -c "data race" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    lock_order=$(grep -c "lock order" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    thread_bugs=$(grep -c "Thread.*Bug" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    unlock_errors=$(grep -c "unlocked a not-locked lock" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    destroy_errors=$(grep -c "destroy.*busy" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    
    # Nettoyer tous les compteurs
    data_races=$(echo "$data_races" | tr -d '\n\r' | sed 's/[^0-9]//g')
    lock_order=$(echo "$lock_order" | tr -d '\n\r' | sed 's/[^0-9]//g')
    thread_bugs=$(echo "$thread_bugs" | tr -d '\n\r' | sed 's/[^0-9]//g')
    unlock_errors=$(echo "$unlock_errors" | tr -d '\n\r' | sed 's/[^0-9]//g')
    destroy_errors=$(echo "$destroy_errors" | tr -d '\n\r' | sed 's/[^0-9]//g')
    
    # Valeurs par défaut si vides
    [ -z "$data_races" ] && data_races=0
    [ -z "$lock_order" ] && lock_order=0
    [ -z "$thread_bugs" ] && thread_bugs=0
    [ -z "$unlock_errors" ] && unlock_errors=0
    [ -z "$destroy_errors" ] && destroy_errors=0
    
    if [ "$error_count" -eq 0 ]; then
        print_color "${GREEN}   ✅ Aucune erreur Helgrind${NC}"
    else
        print_color "${RED}   ❌ $error_count erreurs Helgrind détectées${NC}"
        VALGRIND_ERRORS=$((VALGRIND_ERRORS + 1))
        
        print_color "${YELLOW}   📊 Types d'erreurs:${NC}"
        if [ "$data_races" -gt 0 ]; then
            print_color "${RED}      🏃 Data races: $data_races${NC}"
        fi
        if [ "$lock_order" -gt 0 ]; then
            print_color "${RED}      🔒 Lock order: $lock_order${NC}"
        fi
        if [ "$thread_bugs" -gt 0 ]; then
            print_color "${RED}      🧵 Thread bugs: $thread_bugs${NC}"
        fi
        if [ "$unlock_errors" -gt 0 ]; then
            print_color "${RED}      🔓 Unlock errors: $unlock_errors${NC}"
        fi
        if [ "$destroy_errors" -gt 0 ]; then
            print_color "${RED}      💥 Destroy errors: $destroy_errors${NC}"
        fi
    fi
    print_color ""
}

run_timing_test() {
    print_color "${YELLOW}🧪 TEST CRITIQUE: 2 philosophes timing${NC}"
    print_color "${CYAN}   Args: 2 800 200 200${NC}"
    print_color "${CYAN}   Vérification délai de mort <10ms${NC}"
    
    local attempt=1
    local max_attempts=3
    local valid_count=0
    local total_delay=0
    local delays=()
    
    while [ $attempt -le $max_attempts ]; do
        if [ $attempt -gt 1 ]; then
            print_color "${BLUE}   🔄 Tentative $attempt/${max_attempts}...${NC}"
        fi
        
        timeout 8s $PHILO 2 800 200 200 > /tmp/timing_test_${attempt}.log 2>&1
        local exit_code=$?
        
        if [ ! -f /tmp/timing_test_${attempt}.log ]; then
            print_color "${RED}   ❌ Erreur de création du log (tentative $attempt)${NC}"
            attempt=$((attempt + 1))
            continue
        fi
        
        local death_count=$(grep -c "died" /tmp/timing_test_${attempt}.log 2>/dev/null || echo "0")
        death_count=$(echo "$death_count" | tr -d '\n\r' | sed 's/[^0-9]//g')
        [ -z "$death_count" ] && death_count=0
        
        if [ "$death_count" -gt 0 ]; then
            local death_time=$(grep "died" /tmp/timing_test_${attempt}.log | head -1 | cut -d' ' -f1 2>/dev/null || echo "N/A")
            local last_eat=$(grep "is eating" /tmp/timing_test_${attempt}.log | tail -1 | cut -d' ' -f1 2>/dev/null || echo "N/A")
            
            if [ -n "$last_eat" ] && [ -n "$death_time" ] && [ "$last_eat" != "N/A" ] && [ "$death_time" != "N/A" ]; then
                local delay=$((death_time - last_eat - 800))
                delays+=("$delay")
                total_delay=$((total_delay + delay))
                
                if [ "$delay" -le 10 ] && [ "$delay" -ge 0 ]; then
                    print_color "${GREEN}   ✅ Timing correct (délai: ${delay}ms)${NC}"
                    valid_count=$((valid_count + 1))
                else
                    print_color "${RED}   ❌ Délai incorrect: ${delay}ms (>10ms)${NC}"
                fi
            else
                print_color "${YELLOW}   ⚠️  Pas de repas trouvé pour calculer délai (tentative $attempt)${NC}"
            fi
        else
            if [ $exit_code -eq 124 ]; then
                print_color "${GREEN}   ✅ Pas de mort (timeout atteint) - tentative $attempt${NC}"
                valid_count=$((valid_count + 1))
            else
                print_color "${RED}   ❌ Comportement inattendu (tentative $attempt)${NC}"
            fi
        fi
        
        attempt=$((attempt + 1))
        sleep 0.5
    done
    
    # Décision finale
    if [ $valid_count -ge 2 ]; then
        if [ ${#delays[@]} -gt 0 ]; then
            local avg_delay=$((total_delay / ${#delays[@]}))
            print_color "${GREEN}   🎯 RÉSULTAT: SUCCÈS ($valid_count/3 - délai moyen: ${avg_delay}ms)${NC}"
        else
            print_color "${GREEN}   🎯 RÉSULTAT: SUCCÈS ($valid_count/3 réussites)${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [ $valid_count -eq 1 ]; then
        print_color "${YELLOW}   ⚠️  RÉSULTAT: INSTABLE ($valid_count/3 réussites)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("Test timing: Comportement instable ($valid_count/3 réussites)")
    else
        print_color "${RED}   💥 RÉSULTAT: ÉCHEC ($valid_count/3 réussites)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("Test timing: Échec complet")
    fi
    
    print_color ""
    
    # Nettoyer les fichiers de log temporaires
    rm -f /tmp/timing_test_*.log
}

# Tests principaux avec retry
run_test "1: 1 philosophe doit mourir" "1 800 200 200" "should_die" $TIMEOUT_NORMAL
run_test "2: 5 philosophes boucle infinie" "5 800 200 200" "no_death" 8
run_test "3: 5 philosophes 7 repas chacun" "5 800 200 200 7" "check_meals" $TIMEOUT_NORMAL 35
run_test "4: 4 philosophes limite" "4 410 200 200" "no_death" 6
run_test "5: 4 philosophes mort" "4 310 200 100" "should_die" $TIMEOUT_NORMAL

# Test critique timing avec retry
run_timing_test

print_color "${PURPLE}🔍 PHASE VALGRIND HELGRIND${NC}"
print_color ""

run_valgrind_test "1 philosophe" "1 800 200 200" 10
run_valgrind_test "5 philosophes" "5 800 200 200" 10
run_valgrind_test "5 philosophes 7 repas" "5 800 200 200 7" 15
run_valgrind_test "4 philosophes limite" "4 400 200 200" 10
run_valgrind_test "4 philosophes mort" "4 310 200 200" 10

print_color "${CYAN}================================${NC}"
print_color "${WHITE}      📊 RÉSULTATS FINAUX       ${NC}"
print_color "${CYAN}================================${NC}"

total_tests=$((TESTS_PASSED + TESTS_FAILED))
print_color "${WHITE}Tests fonctionnels: ${GREEN}$TESTS_PASSED${NC}/${GREEN}$total_tests${NC}"

if [ "$VALGRIND_ERRORS" -eq 0 ]; then
    print_color "${WHITE}Tests Valgrind: ${GREEN}✅ TOUS OK${NC}"
else
    print_color "${WHITE}Tests Valgrind: ${RED}❌ $VALGRIND_ERRORS erreurs${NC}"
fi

if [ "$TESTS_FAILED" -gt 0 ]; then
    print_color ""
    print_color "${RED}❌ TESTS ÉCHOUÉS:${NC}"
    for failed_test in "${FAILED_TESTS[@]}"; do
        print_color "${RED}   • $failed_test${NC}"
    done
    print_color ""
    
    print_color "${YELLOW}💡 RECOMMANDATIONS:${NC}"
    
    death_issues=false
    timing_issues=false
    meal_issues=false
    stability_issues=false
    
    for failed_test in "${FAILED_TESTS[@]}"; do
        if [[ "$failed_test" == *"Aucune mort"* ]]; then
            death_issues=true
        elif [[ "$failed_test" == *"Mort inattendue"* ]]; then
            death_issues=true  
        elif [[ "$failed_test" == *"timing"* ]]; then
            timing_issues=true
        elif [[ "$failed_test" == *"Repas"* ]]; then
            meal_issues=true
        elif [[ "$failed_test" == *"instable"* ]]; then
            stability_issues=true
        fi
    done
    
    if [ "$stability_issues" = true ]; then
        print_color "${YELLOW}   ⚡ Problèmes de stabilité détectés:${NC}"
        print_color "      - Comportements incohérents entre les exécutions"
        print_color "      - Possible race condition ou timing critique"
        print_color "      - Vérifier la synchronisation des threads"
        print_color "      - Tester sur différentes charges système"
    fi
    
    if [ "$death_issues" = true ]; then
        print_color "${YELLOW}   🔧 Problèmes de mort détectés:${NC}"
        print_color "      - Vérifier la logique de surveillance (monitor thread)"
        print_color "      - Contrôler les conditions de fin de simulation"
        print_color "      - Tester les paramètres critiques: 1 800 200 200 et 4 310 200 100"
    fi
    
    if [ "$meal_issues" = true ]; then
        print_color "${YELLOW}   🍽️  Problèmes de comptage de repas:${NC}"
        print_color "      - Vérifier que chaque philosophe mange exactement le nombre requis"
        print_color "      - Pour 5 philosophes × 7 repas = 35 repas au total minimum"
        print_color "      - Contrôler la condition d'arrêt après tous les repas"
    fi
    
    if [ "$timing_issues" = true ]; then
        print_color "${YELLOW}   ⏱️  Problèmes de timing détectés:${NC}"
        print_color "      - Optimiser la précision des delays"
        print_color "      - Vérifier la gestion du temps (usleep vs precision timing)"
        print_color "      - Contrôler la détection de mort (<10ms requis)"
    fi
fi

if [ "$TESTS_FAILED" -eq 0 ] && [ "$VALGRIND_ERRORS" -eq 0 ]; then
    print_color "${GREEN}🎉 PROJET VALIDÉ - Prêt pour l'évaluation!${NC}"
elif [ "$TESTS_FAILED" -eq 0 ]; then
    print_color "${YELLOW}⚠️  Fonctionnel OK mais erreurs Valgrind${NC}"
fi

print_color ""
print_color "${BLUE}📝 Logs sauvegardés dans /tmp/test_*.log${NC}"

rm -f /tmp/test_current.log /tmp/valgrind_test.log /tmp/timing_test.log