#!/bin/bash

# ************************************************************************** #
#                                                                            #
#                                                        :::      ::::::::   #
#   test_philo.sh                                      :+:      :+:    :+:   #
#                                                    +:+ +:+         +:+     #
#   By: mpapin <marvin@42.fr>                      +#+  +:+       +#+        #
#                                                +#+#+#+#+#+   +#+           #
#   Created: 2025/06/06 16:00:00 by mpapin            #+#    #+#             #
#   Updated: 2025/06/06 16:00:00 by mpapin           ###   ########.fr       #
#                                                                            #
# ************************************************************************** #

# Fonction print universelle
print_color() {
    printf "$1\n"
}

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIMEOUT_NORMAL=10
TIMEOUT_VALGRIND=30

# Le script ne doit être utilisé QUE dans un projet philosophers
# Pas de support pour exécutable personnalisé
if [ $# -eq 1 ]; then
    print_color "${YELLOW}⚠️  Ce script détecte automatiquement votre projet philosophers${NC}"
    print_color "${BLUE}ℹ️  Aucun argument nécessaire, il trouve ./philo tout seul${NC}"
    print_color ""
fi

# Vérifier qu'on a les fichiers philosophers dans le répertoire de travail
missing_files=()
if [ ! -f "$WORK_DIR/philo.h" ] && [ ! -f "$WORK_DIR/philosophers.h" ]; then
    missing_files+=("philo.h ou philosophers.h")
fi

# Vérifier qu'il y a des fichiers .c dans le répertoire de travail
c_files_found=false
if ls $WORK_DIR/*.c >/dev/null 2>&1; then
    c_files_found=true
elif ls $WORK_DIR/src/*.c >/dev/null 2>&1; then
    c_files_found=true
fi

if [ "$c_files_found" = false ]; then
    missing_files+=("fichiers .c")
fi

if [ ${#missing_files[@]} -gt 0 ]; then
    print_color "${YELLOW}⚠️  Fichiers manquants détectés dans $WORK_DIR:${NC}"
    for file in "${missing_files[@]}"; do
        print_color "${YELLOW}   • $file${NC}"
    done
    print_color ""
    print_color "${BLUE}ℹ️  Le script continuera mais certains tests peuvent échouer${NC}"
    print_color ""
fi

print_color "${CYAN}================================${NC}"
print_color "${WHITE}  🍝      TESTS 42 PHILO    🍝${NC}"
print_color "${CYAN}================================${NC}"
print_color ""

# Vérification qu'on est dans un projet philosophers
project_found=false
project_type=""
philo_path=""

# Cas 1: On est directement dans le dossier du projet philosophers
if [ -f "Makefile" ] && ([ -f "philo.h" ] || ls *.c >/dev/null 2>&1); then
    project_found=true
    project_type="direct"
    philo_path="./philo"
# Cas 2: On est dans un repo avec un sous-dossier philosophers
elif [ -d "philosophers" ] && [ -f "philosophers/Makefile" ]; then
    project_found=true
    project_type="subdirectory"
    philo_path="philosophers/philo"
# Cas 3: On est dans un repo avec des dossiers philo/philo_bonus
elif [ -d "philo" ] && [ -f "philo/Makefile" ]; then
    project_found=true
    project_type="separate_dirs"
    philo_path="philo/philo"
fi

if [ "$project_found" = false ]; then
    print_color "${RED}❌ Erreur: Aucun projet philosophers détecté!${NC}"
    print_color ""
    print_color "${YELLOW}💡 Solutions:${NC}"
    print_color "   ${CYAN}1.${NC} Vous êtes dans le projet philosophers:"
    print_color "      ${WHITE}philosophers/${NC}"
    print_color "      ${WHITE}├── Makefile${NC}"
    print_color "      ${WHITE}├── philo.h${NC}"
    print_color "      ${WHITE}├── *.c${NC}"
    print_color "      ${WHITE}└── test_philo.sh ${CYAN}← Ce script${NC}"
    print_color ""
    print_color "   ${CYAN}2.${NC} Ou dans un repo avec sous-dossier:"
    print_color "      ${WHITE}mon_repo/${NC}"
    print_color "      ${WHITE}├── philosophers/${NC}"
    print_color "      ${WHITE}│   ├── Makefile${NC}"
    print_color "      ${WHITE}│   ├── *.c${NC}"
    print_color "      ${WHITE}│   └── philo${NC}"
    print_color "      ${WHITE}└── test_philo.sh ${CYAN}← Ce script${NC}"
    print_color ""
    print_color "   ${CYAN}3.${NC} Ou avec dossiers séparés:"
    print_color "      ${WHITE}mon_repo/${NC}"
    print_color "      ${WHITE}├── philo/${NC}"
    print_color "      ${WHITE}│   ├── Makefile${NC}"
    print_color "      ${WHITE}│   └── *.c${NC}"
    print_color "      ${WHITE}├── philo_bonus/...${NC}"
    print_color "      ${WHITE}└── test_philo.sh ${CYAN}← Ce script${NC}"
    print_color ""
    print_color "${BLUE}📁 Répertoire actuel: $(pwd)${NC}"
    print_color "${BLUE}📋 Contenu: $(ls -la | head -10)${NC}"
    print_color ""
    exit 1
fi

# Afficher le type de projet détecté
case $project_type in
    "direct")
        print_color "${GREEN}✅ Projet philosophers détecté (mode direct)${NC}"
        WORK_DIR="."
        ;;
    "subdirectory")
        print_color "${GREEN}✅ Projet philosophers détecté (sous-dossier philosophers/)${NC}"
        WORK_DIR="philosophers"
        ;;
    "separate_dirs")
        print_color "${GREEN}✅ Projet philosophers détecté (dossier philo/ séparé)${NC}"
        WORK_DIR="philo"
        ;;
esac

# Définir le chemin de l'exécutable
PHILO="$philo_path"

print_color "${BLUE}🎯 Exécutable cible: $PHILO${NC}"
print_color ""

# Vérification de l'exécutable
if [ ! -f "$PHILO" ]; then
    print_color "${RED}❌ Exécutable $PHILO non trouvé!${NC}"
    print_color ""
    print_color "${YELLOW}💡 Solutions:${NC}"
    print_color "   ${CYAN}1.${NC} Compiler d'abord: ${WHITE}make${NC}"
    print_color "   ${CYAN}2.${NC} Vérifier que vous êtes dans le bon dossier"
    print_color "   ${CYAN}3.${NC} Structure attendue:"
    print_color "      ${WHITE}votre_projet_philosophers/${NC}"
    print_color "      ${WHITE}├── Makefile${NC}"
    print_color "      ${WHITE}├── philo.h${NC}"
    print_color "      ${WHITE}├── *.c${NC}"
    print_color "      ${WHITE}├── philo ${CYAN}← Après compilation${NC}"
    print_color "      ${WHITE}└── test_philo.sh ${CYAN}← Ce script${NC}"
    print_color ""
    print_color "${BLUE}📁 Répertoire actuel: $(pwd)${NC}"
    print_color "${BLUE}📋 Fichiers présents: $(ls -la | grep -E '\.(c|h|sh)$|Makefile|philo

# Auto-détection du Makefile et compilation si nécessaire
if [ -f "$WORK_DIR/Makefile" ]; then
    # Vérifier si l'exécutable existe et s'il est plus récent que les sources
    need_compile=false
    
    if [ ! -f "$PHILO" ]; then
        need_compile=true
    else
        # Vérifier si des fichiers .c sont plus récents que l'exécutable
        if ls $WORK_DIR/*.c >/dev/null 2>&1; then
            for source_file in $WORK_DIR/*.c; do
                if [ "$source_file" -nt "$PHILO" ]; then
                    need_compile=true
                    break
                fi
            done
        fi
        if ls $WORK_DIR/src/*.c >/dev/null 2>&1; then
            for source_file in $WORK_DIR/src/*.c; do
                if [ "$source_file" -nt "$PHILO" ]; then
                    need_compile=true
                    break
                fi
            done
        fi
    fi
    
    if [ "$need_compile" = true ]; then
        print_color "${BLUE}🔨 Compilation automatique dans $WORK_DIR...${NC}"
        if (cd "$WORK_DIR" && make > /dev/null 2>&1); then
            print_color "${GREEN}✅ Compilation OK${NC}"
        else
            print_color "${RED}❌ Erreur de compilation${NC}"
            print_color "${YELLOW}📋 Sortie de make dans $WORK_DIR:${NC}"
            (cd "$WORK_DIR" && make)
            exit 1
        fi
    else
        print_color "${GREEN}✅ Exécutable $PHILO déjà à jour${NC}"
    fi
else
    print_color "${RED}❌ Makefile non trouvé dans $WORK_DIR!${NC}"
    print_color "${YELLOW}⚠️  Structure de projet philosophers invalide${NC}"
    exit 1
fi

# Vérifier les permissions d'exécution
if [ ! -x "$PHILO" ]; then
    print_color "${YELLOW}⚠️  Ajout des permissions d'exécution...${NC}"
    chmod +x "$PHILO"
fi

print_color ""

# Variables de résultats
TESTS_PASSED=0
TESTS_FAILED=0
VALGRIND_ERRORS=0
FAILED_TESTS=()  # Tableau pour stocker les tests échoués

# Fonction de test
run_test() {
    local test_name="$1"
    local args="$2"
    local expected_death="$3"  # "should_die" ou "no_death"
    local timeout="$4"
    
    print_color "${YELLOW}🧪 TEST$test_name${NC}"
    print_color "${CYAN}   Args: $args${NC}"
    print_color "${CYAN}   Timeout: ${timeout}s${NC}"
    
    timeout ${timeout}s $PHILO $args > /tmp/test_current.log 2>&1
    exit_code=$?
    
    # Analyser les résultats
    death_count=$(grep -c "died" /tmp/test_current.log 2>/dev/null || echo "0")
    total_lines=$(wc -l < /tmp/test_current.log 2>/dev/null || echo "0")
    
    if [ "$expected_death" = "should_die" ]; then
        if [ "$death_count" -gt 0 ]; then
            death_time=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f1)
            death_philo=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f2)
            print_color "${GREEN}   ✅ Mort attendue détectée${NC}"
            print_color "${WHITE}      💀 Philosophe $death_philo mort à ${death_time}ms${NC}"
            print_color "${WHITE}      📊 Total actions: $total_lines${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_color "${RED}   ❌ Aucune mort détectée (attendue!)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name: Aucune mort détectée")
        fi
    else
        if [ $exit_code -eq 124 ]; then
            print_color "${GREEN}   ✅ Timeout atteint (pas de mort)${NC}"
            print_color "${WHITE}      📊 Actions: $total_lines lignes${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        elif [ "$death_count" -eq 0 ]; then
            print_color "${GREEN}   ✅ Programme terminé sans mort${NC}"
            print_color "${WHITE}      📊 Actions: $total_lines lignes${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            death_time=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f1)
            death_philo=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f2)
            print_color "${RED}   ❌ Mort inattendue!${NC}"
            print_color "${RED}      💀 Philosophe $death_philo mort à ${death_time}ms${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name: Mort inattendue (philo $death_philo à ${death_time}ms)")
        fi
    fi
    print_color ""
}

# Fonction test Valgrind
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
    
    # Analyse des erreurs Helgrind
    error_summary=$(grep "ERROR SUMMARY:" /tmp/valgrind_test.log | tail -1)
    error_count=$(echo "$error_summary" | grep -o "[0-9]\+ errors" | cut -d' ' -f1 2>/dev/null || echo "0")
    
    # Compter les types d'erreurs
    data_races=$(grep -c "data race" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    lock_order=$(grep -c "lock order" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    thread_bugs=$(grep -c "Thread.*Bug" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    unlock_errors=$(grep -c "unlocked a not-locked lock" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    destroy_errors=$(grep -c "destroy.*busy" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    
    if [ "$error_count" -eq 0 ]; then
        print_color "${GREEN}   ✅ Aucune erreur Helgrind${NC}"
    else
        print_color "${RED}   ❌ $error_count erreurs Helgrind détectées${NC}"
        VALGRIND_ERRORS=$((VALGRIND_ERRORS + 1))
        
        # Détail des types d'erreurs
        print_color "${YELLOW}   📊 Types d'erreurs:${NC}"
        [ "$data_races" -gt 0 ] && print_color "${RED}      🏃 Data races: $data_races${NC}"
        [ "$lock_order" -gt 0 ] && print_color "${RED}      🔒 Lock order: $lock_order${NC}"
        [ "$thread_bugs" -gt 0 ] && print_color "${RED}      🧵 Thread bugs: $thread_bugs${NC}"
        [ "$unlock_errors" -gt 0 ] && print_color "${RED}      🔓 Unlock errors: $unlock_errors${NC}"
        [ "$destroy_errors" -gt 0 ] && print_color "${RED}      💥 Destroy errors: $destroy_errors${NC}"
    fi
    print_color ""
}

# TEST 1: 1 800 200 200 - Le philosophe doit mourir
run_test "1: 1 philosophe doit mourir" "1 800 200 200" "should_die" $TIMEOUT_NORMAL

# TEST 2: 5 800 200 200 - Aucun ne doit mourir
run_test "2: 5 philosophes boucle infinie" "5 800 200 200" "no_death" 8

# TEST 3: 5 800 200 200 7 - Stop quand tous ont mangé 7 fois
run_test "3: 5 philosophes 7 repas" "5 800 200 200 7" "no_death" $TIMEOUT_NORMAL

# TEST 4: 4 410 200 200 - Aucun ne doit mourir
run_test "4: 4 philosophes limite" "4 410 200 200" "no_death" 6

# TEST 5: 4 310 200 100 - Un doit mourir
run_test "5: 4 philosophes mort" "4 310 200 100" "should_die" $TIMEOUT_NORMAL

# TEST 6: 2 philosophes - Test timing critique
print_color "${YELLOW}🧪 TEST CRITIQUE: 2 philosophes timing${NC}"
print_color "${CYAN}   Args: 2 800 200 200${NC}"
print_color "${CYAN}   Vérification délai de mort <10ms${NC}"

timeout 8s $PHILO 2 800 200 200 > /tmp/timing_test.log 2>&1
exit_code=$?

if [ ! -f /tmp/timing_test.log ]; then
    print_color "${RED}   ❌ Erreur de création du log${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("Test timing: Erreur de création du log")
else
    death_count=$(grep -c "died" /tmp/timing_test.log 2>/dev/null || echo "0")
    if [ "$death_count" -gt 0 ]; then
        death_time=$(grep "died" /tmp/timing_test.log | head -1 | cut -d' ' -f1)
        last_eat=$(grep "is eating" /tmp/timing_test.log | tail -1 | cut -d' ' -f1)
        if [ -n "$last_eat" ] && [ -n "$death_time" ]; then
            delay=$((death_time - last_eat - 800))
            if [ "$delay" -le 10 ] && [ "$delay" -ge 0 ]; then
                print_color "${GREEN}   ✅ Timing correct (délai: ${delay}ms)${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                print_color "${RED}   ❌ Délai incorrect: ${delay}ms (>10ms)${NC}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        else
            print_color "${YELLOW}   ⚠️  Pas de repas trouvé pour calculer délai${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [ $exit_code -eq 124 ]; then
            print_color "${GREEN}   ✅ Pas de mort (timeout atteint)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_color "${RED}   ❌ Comportement inattendu${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
fi
print_color ""

# TESTS VALGRIND sur cas critiques
print_color "${PURPLE}🔍 PHASE VALGRIND HELGRIND${NC}"
print_color ""

run_valgrind_test "1 philosophe" "1 800 200 200" 15
run_valgrind_test "5 philosophes" "5 800 200 200" 10
run_valgrind_test "2 philosophes" "2 800 200 200" 10

# RÉSULTATS FINAUX
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

# Détail des échecs
if [ "$TESTS_FAILED" -gt 0 ]; then
    print_color ""
    print_color "${RED}❌ TESTS ÉCHOUÉS:${NC}"
    for failed_test in "${FAILED_TESTS[@]}"; do
        print_color "${RED}   • $failed_test${NC}"
    done
    print_color ""
    
    # Recommandations par type d'erreur
    print_color "${YELLOW}💡 RECOMMANDATIONS:${NC}"
    
    # Analyser les types d'erreurs
    death_issues=false
    timing_issues=false
    
    for failed_test in "${FAILED_TESTS[@]}"; do
        if [[ "$failed_test" == *"Aucune mort"* ]]; then
            death_issues=true
        elif [[ "$failed_test" == *"Mort inattendue"* ]]; then
            death_issues=true  
        elif [[ "$failed_test" == *"timing"* ]]; then
            timing_issues=true
        fi
    done
    
    if [ "$death_issues" = true ]; then
        print_color "${YELLOW}   🔧 Problèmes de mort détectés:${NC}"
        print_color "      - Vérifier la logique de surveillance (monitor thread)"
        print_color "      - Contrôler les conditions de fin de simulation"
        print_color "      - Tester les paramètres critiques: 1 800 200 200 et 4 310 200 100"
    fi
    
    if [ "$timing_issues" = true ]; then
        print_color "${YELLOW}   ⏱️  Problèmes de timing détectés:${NC}"
        print_color "      - Optimiser la précision des delays"
        print_color "      - Vérifier la gestion du temps (usleep vs precision timing)"
        print_color "      - Contrôler la détection de mort (<10ms requis)"
    fi
fi

# Note finale
if [ "$TESTS_FAILED" -eq 0 ] && [ "$VALGRIND_ERRORS" -eq 0 ]; then
    print_color "${GREEN}🎉 PROJET VALIDÉ - Prêt pour l'évaluation!${NC}"
elif [ "$TESTS_FAILED" -eq 0 ]; then
    print_color "${YELLOW}⚠️  Fonctionnel OK mais erreurs Valgrind${NC}"
else
    print_color "${RED}❌ ÉCHEC - Tests fonctionnels à corriger${NC}"
    print_color "${BLUE}📋 Corrige les erreurs ci-dessus avant l'évaluation${NC}"
fi

print_color ""
print_color "${BLUE}📝 Logs sauvegardés dans /tmp/test_*.log${NC}"

# Nettoyage
rm -f /tmp/test_current.log /tmp/valgrind_test.log /tmp/timing_test.log | wc -l) fichiers pertinents${NC}"
    print_color ""
    exit 1
fi

# Auto-détection du Makefile et compilation si nécessaire
if [ -f "Makefile" ] && [ "$PHILO" = "./philo" ]; then
    # Vérifier si l'exécutable existe et s'il est plus récent que les sources
    need_compile=false
    
    if [ ! -f "$PHILO" ]; then
        need_compile=true
    else
        # Vérifier si des fichiers .c sont plus récents que l'exécutable
        if ls *.c >/dev/null 2>&1; then
            for source_file in *.c; do
                if [ "$source_file" -nt "$PHILO" ]; then
                    need_compile=true
                    break
                fi
            done
        fi
        if ls src/*.c >/dev/null 2>&1; then
            for source_file in src/*.c; do
                if [ "$source_file" -nt "$PHILO" ]; then
                    need_compile=true
                    break
                fi
            done
        fi
    fi
    
    if [ "$need_compile" = true ]; then
        print_color "${BLUE}🔨 Compilation automatique détectée...${NC}"
        if make > /dev/null 2>&1; then
            print_color "${GREEN}✅ Compilation OK${NC}"
        else
            print_color "${RED}❌ Erreur de compilation${NC}"
            print_color "${YELLOW}📋 Sortie de make:${NC}"
            make
            exit 1
        fi
    else
        print_color "${GREEN}✅ Exécutable $PHILO déjà à jour${NC}"
    fi
elif [ "$PHILO" = "./philo" ]; then
    print_color "${YELLOW}⚠️  Aucun Makefile trouvé, utilisation de l'exécutable existant${NC}"
else
    print_color "${BLUE}ℹ️  Utilisation de l'exécutable personnalisé: $PHILO${NC}"
fi

# Vérifier les permissions d'exécution
if [ ! -x "$PHILO" ]; then
    print_color "${YELLOW}⚠️  Ajout des permissions d'exécution...${NC}"
    chmod +x "$PHILO"
fi

print_color ""

# Variables de résultats
TESTS_PASSED=0
TESTS_FAILED=0
VALGRIND_ERRORS=0
FAILED_TESTS=()  # Tableau pour stocker les tests échoués

# Fonction de test
run_test() {
    local test_name="$1"
    local args="$2"
    local expected_death="$3"  # "should_die" ou "no_death"
    local timeout="$4"
    
    print_color "${YELLOW}🧪 TEST$test_name${NC}"
    print_color "${CYAN}   Args: $args${NC}"
    print_color "${CYAN}   Timeout: ${timeout}s${NC}"
    
    timeout ${timeout}s $PHILO $args > /tmp/test_current.log 2>&1
    exit_code=$?
    
    # Analyser les résultats
    death_count=$(grep -c "died" /tmp/test_current.log 2>/dev/null || echo "0")
    total_lines=$(wc -l < /tmp/test_current.log 2>/dev/null || echo "0")
    
    if [ "$expected_death" = "should_die" ]; then
        if [ "$death_count" -gt 0 ]; then
            death_time=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f1)
            death_philo=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f2)
            print_color "${GREEN}   ✅ Mort attendue détectée${NC}"
            print_color "${WHITE}      💀 Philosophe $death_philo mort à ${death_time}ms${NC}"
            print_color "${WHITE}      📊 Total actions: $total_lines${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_color "${RED}   ❌ Aucune mort détectée (attendue!)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name: Aucune mort détectée")
        fi
    else
        if [ $exit_code -eq 124 ]; then
            print_color "${GREEN}   ✅ Timeout atteint (pas de mort)${NC}"
            print_color "${WHITE}      📊 Actions: $total_lines lignes${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        elif [ "$death_count" -eq 0 ]; then
            print_color "${GREEN}   ✅ Programme terminé sans mort${NC}"
            print_color "${WHITE}      📊 Actions: $total_lines lignes${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            death_time=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f1)
            death_philo=$(grep "died" /tmp/test_current.log | head -1 | cut -d' ' -f2)
            print_color "${RED}   ❌ Mort inattendue!${NC}"
            print_color "${RED}      💀 Philosophe $death_philo mort à ${death_time}ms${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_TESTS+=("$test_name: Mort inattendue (philo $death_philo à ${death_time}ms)")
        fi
    fi
    print_color ""
}

# Fonction test Valgrind
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
    
    # Analyse des erreurs Helgrind
    error_summary=$(grep "ERROR SUMMARY:" /tmp/valgrind_test.log | tail -1)
    error_count=$(echo "$error_summary" | grep -o "[0-9]\+ errors" | cut -d' ' -f1 2>/dev/null || echo "0")
    
    # Compter les types d'erreurs
    data_races=$(grep -c "data race" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    lock_order=$(grep -c "lock order" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    thread_bugs=$(grep -c "Thread.*Bug" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    unlock_errors=$(grep -c "unlocked a not-locked lock" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    destroy_errors=$(grep -c "destroy.*busy" /tmp/valgrind_test.log 2>/dev/null || echo "0")
    
    if [ "$error_count" -eq 0 ]; then
        print_color "${GREEN}   ✅ Aucune erreur Helgrind${NC}"
    else
        print_color "${RED}   ❌ $error_count erreurs Helgrind détectées${NC}"
        VALGRIND_ERRORS=$((VALGRIND_ERRORS + 1))
        
        # Détail des types d'erreurs
        print_color "${YELLOW}   📊 Types d'erreurs:${NC}"
        [ "$data_races" -gt 0 ] && print_color "${RED}      🏃 Data races: $data_races${NC}"
        [ "$lock_order" -gt 0 ] && print_color "${RED}      🔒 Lock order: $lock_order${NC}"
        [ "$thread_bugs" -gt 0 ] && print_color "${RED}      🧵 Thread bugs: $thread_bugs${NC}"
        [ "$unlock_errors" -gt 0 ] && print_color "${RED}      🔓 Unlock errors: $unlock_errors${NC}"
        [ "$destroy_errors" -gt 0 ] && print_color "${RED}      💥 Destroy errors: $destroy_errors${NC}"
    fi
    print_color ""
}

# TEST 1: 1 800 200 200 - Le philosophe doit mourir
run_test "1: 1 philosophe doit mourir" "1 800 200 200" "should_die" $TIMEOUT_NORMAL

# TEST 2: 5 800 200 200 - Aucun ne doit mourir
run_test "2: 5 philosophes boucle infinie" "5 800 200 200" "no_death" 8

# TEST 3: 5 800 200 200 7 - Stop quand tous ont mangé 7 fois
run_test "3: 5 philosophes 7 repas" "5 800 200 200 7" "no_death" $TIMEOUT_NORMAL

# TEST 4: 4 410 200 200 - Aucun ne doit mourir
run_test "4: 4 philosophes limite" "4 410 200 200" "no_death" 6

# TEST 5: 4 310 200 100 - Un doit mourir
run_test "5: 4 philosophes mort" "4 310 200 100" "should_die" $TIMEOUT_NORMAL

# TEST 6: 2 philosophes - Test timing critique
print_color "${YELLOW}🧪 TEST CRITIQUE: 2 philosophes timing${NC}"
print_color "${CYAN}   Args: 2 800 200 200${NC}"
print_color "${CYAN}   Vérification délai de mort <10ms${NC}"

timeout 8s $PHILO 2 800 200 200 > /tmp/timing_test.log 2>&1
exit_code=$?

if [ ! -f /tmp/timing_test.log ]; then
    print_color "${RED}   ❌ Erreur de création du log${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("Test timing: Erreur de création du log")
else
    death_count=$(grep -c "died" /tmp/timing_test.log 2>/dev/null || echo "0")
    if [ "$death_count" -gt 0 ]; then
        death_time=$(grep "died" /tmp/timing_test.log | head -1 | cut -d' ' -f1)
        last_eat=$(grep "is eating" /tmp/timing_test.log | tail -1 | cut -d' ' -f1)
        if [ -n "$last_eat" ] && [ -n "$death_time" ]; then
            delay=$((death_time - last_eat - 800))
            if [ "$delay" -le 10 ] && [ "$delay" -ge 0 ]; then
                print_color "${GREEN}   ✅ Timing correct (délai: ${delay}ms)${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                print_color "${RED}   ❌ Délai incorrect: ${delay}ms (>10ms)${NC}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        else
            print_color "${YELLOW}   ⚠️  Pas de repas trouvé pour calculer délai${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [ $exit_code -eq 124 ]; then
            print_color "${GREEN}   ✅ Pas de mort (timeout atteint)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_color "${RED}   ❌ Comportement inattendu${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
fi
print_color ""

# TESTS VALGRIND sur cas critiques
print_color "${PURPLE}🔍 PHASE VALGRIND HELGRIND${NC}"
print_color ""

run_valgrind_test "1 philosophe" "1 800 200 200" 15
run_valgrind_test "5 philosophes" "5 800 200 200" 10
run_valgrind_test "2 philosophes" "2 800 200 200" 10

# RÉSULTATS FINAUX
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

# Détail des échecs
if [ "$TESTS_FAILED" -gt 0 ]; then
    print_color ""
    print_color "${RED}❌ TESTS ÉCHOUÉS:${NC}"
    for failed_test in "${FAILED_TESTS[@]}"; do
        print_color "${RED}   • $failed_test${NC}"
    done
    print_color ""
    
    # Recommandations par type d'erreur
    print_color "${YELLOW}💡 RECOMMANDATIONS:${NC}"
    
    # Analyser les types d'erreurs
    death_issues=false
    timing_issues=false
    
    for failed_test in "${FAILED_TESTS[@]}"; do
        if [[ "$failed_test" == *"Aucune mort"* ]]; then
            death_issues=true
        elif [[ "$failed_test" == *"Mort inattendue"* ]]; then
            death_issues=true  
        elif [[ "$failed_test" == *"timing"* ]]; then
            timing_issues=true
        fi
    done
    
    if [ "$death_issues" = true ]; then
        print_color "${YELLOW}   🔧 Problèmes de mort détectés:${NC}"
        print_color "      - Vérifier la logique de surveillance (monitor thread)"
        print_color "      - Contrôler les conditions de fin de simulation"
        print_color "      - Tester les paramètres critiques: 1 800 200 200 et 4 310 200 100"
    fi
    
    if [ "$timing_issues" = true ]; then
        print_color "${YELLOW}   ⏱️  Problèmes de timing détectés:${NC}"
        print_color "      - Optimiser la précision des delays"
        print_color "      - Vérifier la gestion du temps (usleep vs precision timing)"
        print_color "      - Contrôler la détection de mort (<10ms requis)"
    fi
fi

# Note finale
if [ "$TESTS_FAILED" -eq 0 ] && [ "$VALGRIND_ERRORS" -eq 0 ]; then
    print_color "${GREEN}🎉 PROJET VALIDÉ - Prêt pour l'évaluation!${NC}"
elif [ "$TESTS_FAILED" -eq 0 ]; then
    print_color "${YELLOW}⚠️  Fonctionnel OK mais erreurs Valgrind${NC}"
else
    print_color "${RED}❌ ÉCHEC - Tests fonctionnels à corriger${NC}"
    print_color "${BLUE}📋 Corrige les erreurs ci-dessus avant l'évaluation${NC}"
fi

print_color ""
print_color "${BLUE}📝 Logs sauvegardés dans /tmp/test_*.log${NC}"

# Nettoyage
rm -f /tmp/test_current.log /tmp/valgrind_test.log /tmp/timing_test.log