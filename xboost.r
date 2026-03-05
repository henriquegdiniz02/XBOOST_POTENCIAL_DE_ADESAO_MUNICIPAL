# ============================================================
# PROJETO: Modelo de Priorização de Adesão Municipal
# OBS: Dados NÃO versionados (uso local / privado)
# ============================================================

# Pacotes
library(tidyverse)
library(tidymodels)
library(recipes)
library(parsnip)
library(yardstick)

options(scipen = 999)

# ============================================================
# LEITURA DE DADOS (NÃO VERSIONADOS)
# ------------------------------------------------------------
# Substitua estas leituras pelas suas próprias fontes locais
# ============================================================

# df <- read_sheet("URL_DO_GOOGLE_SHEETS", sheet = "Status", skip = 2)
# muni <- read_xlsx("CAMINHO_LOCAL/Municipios.xlsx")
# pref <- read_xlsx("CAMINHO_LOCAL/Prefeitos.xlsx")

# ============================================================
# TRATAMENTO DOS DADOS
# ============================================================

# df <- df %>%
#   select(`Código IBGE`, `Publicação no IOF`) %>%
#   filter(`Publicação no IOF` == "Publicado") %>%
#   mutate(Aderido = 1) %>%
#   select(`Código IBGE`, Aderido)

# muni <- muni %>%
#   select(Municipio, IBGE, Populacao, Mesorregiao, IDMH) %>%
#   rename(CodigoIBGE = IBGE) %>%
#   filter(CodigoIBGE != "9999999")

# pref <- pref %>%
#   select(CodigoIBGE, Partido)

# ============================================================
# CRIAÇÃO DA VARIÁVEL "BASE"
# ============================================================

partidos_base <- c(
  "PSD", "PP", "UNIÃO", "NOVO", "PMN", "PODEMOS", "AVANTE",
  "PDT", "CIDADANIA", "REPUBLICANOS", "PRD", "MDB",
  "PSDB", "PSB", "SOLIDARIEDADE"
)

# pref <- pref %>%
#   mutate(
#     Base = if_else(Partido %in% partidos_base, 1, 0)
#   )

# ============================================================
# BASE FINAL DE MODELAGEM
# ============================================================

# df_final <- muni %>%
#   left_join(df, by = c("CodigoIBGE" = "Código IBGE")) %>%
#   left_join(pref, by = "CodigoIBGE") %>%
#   mutate(
#     Aderido = if_else(is.na(Aderido), 0, 1),
#     Aderido = factor(Aderido, levels = c(1, 0))
#   ) %>%
#   select(
#     Municipio,
#     Populacao,
#     Base,
#     IDMH,
#     Mesorregiao,
#     Aderido
#   ) %>%
#   drop_na()

# ============================================================
# SPLIT TREINO / TESTE
# ============================================================

set.seed(123)

# data_split <- initial_split(df_final, prop = 0.8, strata = Aderido)
# train_data <- training(data_split)
# test_data  <- testing(data_split)

# ============================================================
# RECEITA DE PRÉ-PROCESSAMENTO
# ============================================================

# rec_modelo <- recipe(Aderido ~ ., data = train_data) %>%
#   update_role(Municipio, new_role = "id") %>%
#   step_dummy(Mesorregiao) %>%
#   step_zv(all_predictors()) %>%
#   step_normalize(Populacao, IDMH)

# rec_prep <- prep(rec_modelo, training = train_data)

# train_proc <- bake(rec_prep, new_data = NULL)
# test_proc  <- bake(rec_prep, new_data = test_data)

# ============================================================
# ESPECIFICAÇÃO DO MODELO (XGBOOST)
# ============================================================

modelo_xgb <- boost_tree(
  trees = 500,
  tree_depth = 4,
  learn_rate = 0.01,
  loss_reduction = 0.01
) %>%
  set_engine("xgboost") %>%
  set_mode("classification")

# ============================================================
# TREINAMENTO
# ============================================================

# fit_modelo <- modelo_xgb %>%
#   fit(Aderido ~ ., data = train_proc %>% select(-Municipio))

# ============================================================
# AVALIAÇÃO DO MODELO
# ============================================================

# pred_class <- predict(fit_modelo, test_proc)
# pred_prob  <- predict(fit_modelo, test_proc, type = "prob")

# resultados_teste <- test_proc %>%
#   select(Aderido, Municipio) %>%
#   bind_cols(pred_class, pred_prob)

# Confusion Matrix
# conf_mat(resultados_teste, truth = Aderido, estimate = .pred_class)

# AUC
# roc_auc(resultados_teste, truth = Aderido, .pred_1)

# Curva ROC
# resultados_teste %>%
#   roc_curve(truth = Aderido, .pred_1) %>%
#   autoplot()

# ============================================================
# SCORING DOS MUNICÍPIOS NÃO ADERIDOS
# ============================================================

# nao_aderidos_raw <- df_final %>%
#   filter(Aderido == 0)

# nao_aderidos_proc <- bake(rec_prep, new_data = nao_aderidos_raw)

# predicoes <- predict(fit_modelo, nao_aderidos_proc, type = "prob")

# ranking_adesao <- nao_aderidos_raw %>%
#   select(Municipio, Populacao, Base) %>%
#   bind_cols(predicoes) %>%
#   rename(Probabilidade = .pred_1) %>%
#   arrange(desc(Probabilidade)) %>%
#   mutate(
#     Prioridade = case_when(
#       Probabilidade >= 0.8 ~ "Urgente (Muito Alta)",
#       Probabilidade >= 0.6 ~ "Alta",
#       Probabilidade >= 0.4 ~ "Média",
#       TRUE ~ "Baixa"
#     ),
#     Estrategia = case_when(
#       Probabilidade >= 0.7 ~ "Prioridade Total: Perfil idêntico a aderidos",
#       Probabilidade >= 0.4 ~ "Potencial: Necessita engajamento",
#       TRUE ~ "Baixa Probabilidade: Monitorar"
#     )
#   )

# ============================================================
# FIM DO SCRIPT
# ============================================================
