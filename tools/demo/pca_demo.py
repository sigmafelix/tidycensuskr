## Date: 2025-11-25

from geofacetpy import geofacet
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import pandas as pd
import numpy as np
from pycensuskr import CensusKR
from functools import reduce

census = CensusKR()

# Fetch data from different census types
df_hou = census.anycensus(year=2020, type="housing", level="adm2")
df_hou = (df_hou
    .groupby(['adm1_code', 'adm2_code', 'year', 'type'])
    .apply(lambda group: group.fillna(method='ffill').fillna(method='bfill'))
    .reset_index(drop=True)
    .drop_duplicates()
)

df_pop = census.anycensus(year=2020, type="population", level="adm2")
df_mort = census.anycensus(year=2020, type="mortality", level="adm2")
df_eco = census.anycensus(year=2020, type="economy", level="adm2")
df_tax = census.anycensus(year=2020, type="tax", level="adm2")
df_ss = census.anycensus(year=2020, type="social security", level="adm2")

# Clean economy data
df_eco_x = df_eco.copy()
df_eco_x.columns = df_eco_x.columns.str.lower().str.replace(' ', '_')
df_eco_x = df_eco_x.fillna(0)

# Merge all dataframes
df_wide = reduce(
    lambda left, right: pd.merge(
        left, right,
        on=['adm1', 'adm1_code', 'adm2', 'adm2_code', 'year'],
        how='left'
    ),
    [df_hou, df_pop, df_mort, df_eco_x, df_ss]
)
df_wide = df_wide.drop(columns=['type'], errors='ignore')

# Merge with tax data
df_wide['adm2_code'] = df_wide['adm2_code'].astype(int)
df_wide = df_wide.merge(df_tax, how='left')

# Aggregate and transform data
df_wide['adm2_code_'] = df_wide['adm2_code'].astype(str).str[:4] + '0'

agg_dict = {}
for col in df_wide.select_dtypes(include=[np.number]).columns:
    if any(x in col for x in ['households', 'income', 'housing', 'grdp', 'security']):
        agg_dict[col] = 'sum'
    elif any(x in col for x in ['fertility', 'causes']):
        agg_dict[col] = 'mean'

df_wide_re = (df_wide
    .groupby('adm2_code_')
    .agg({**agg_dict, 'adm2': 'first'})
    .reset_index()
)

# Create final features
df_wide_re['persons_per_housing'] = (
    df_wide_re['all households_total_prs'] / df_wide_re['housing types_total_cnt']
)
df_wide_re['tax_income_per_capita'] = (
    df_wide_re['income_general_mkr'] / df_wide_re['all households_total_prs']
)
df_wide_re['tax_labor_per_capita'] = (
    df_wide_re['income_labor_mkr'] / df_wide_re['all households_total_prs']
)
df_wide_re['sex_ratio'] = (
    100 * df_wide_re['all households_male_prs'] / df_wide_re['all households_female_prs']
)
df_wide_re['mortality_rate'] = df_wide_re['all causes_total_p1p']
df_wide_re['fertility_rate'] = df_wide_re['fertility_total_brt']
df_wide_re['security_rate'] = (
    100 * (df_wide_re['basic living security_female_prs'] + 
           df_wide_re['basic living security_male_prs']) /
    df_wide_re['all households_total_prs']
)

# Add per capita GRDP columns
grdp_cols = [col for col in df_wide_re.columns if 'grdp' in col.lower()]
for col in grdp_cols:
    df_wide_re[f"{col}_percapita"] = (
        df_wide_re[col] / df_wide_re['all households_total_prs']
    )

# PCA with df_wide_re
features = [
    'persons_per_housing', 'tax_income_per_capita', 'tax_labor_per_capita',
    'sex_ratio', 'mortality_rate', 'fertility_rate', 'security_rate'
] + [f"{col}_percapita" for col in grdp_cols]

x = df_wide_re[features].values
x = StandardScaler().fit_transform(x)
pca = PCA(n_components=5)
principalComponents = pca.fit_transform(x)
df_pca = pd.DataFrame(data=principalComponents, columns=['PC1', 'PC2'])
df_pca = pd.concat([df_wide_re[['adm2_code_', 'adm2']], df_pca], axis=1)

# Plot PCA results
plt.figure(figsize=(10, 8))
sns.scatterplot(
    data=df_pca, x='PC1', y='PC2',
    hue='adm2', palette='tab20', legend=None
)
plt.title('PCA of Socio-Economic Indicators by District')
plt.xlabel('Principal Component 1')
plt.ylabel('Principal Component 2')
plt.grid()
plt.show()