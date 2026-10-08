import os
import pandas as pd
import matplotlib.pyplot as plt

def generate_visualizations():
    os.makedirs('visualizations', exist_ok=True)
 
    # Load and clean data
    orders = pd.read_csv('data/orders.csv')
    products = pd.read_csv('data/products.csv')
 
    # Clean payment method and deduplicate
    dup_cols = ['customer_id', 'product_id', 'order_date', 'quantity',
                'discount_pct', 'payment_method', 'rating', 'returned']
    orders['payment_method'] = orders['payment_method'].astype(str).str.strip().str.upper()
    orders_clean = orders.drop_duplicates(subset=dup_cols, keep='first').copy()
    orders_clean['discount_pct'] = orders_clean['discount_pct'].fillna(0)
 
    merged = orders_clean.merge(products, on='product_id')
    merged['order_value'] = merged['quantity'] * merged['price'] * (1.0 - merged['discount_pct'] / 100.0)
 
    # -------------------------------------------------------------------------
    # Visualization 1: Return Rate by Payment Method
    # -------------------------------------------------------------------------
    pm_stats = merged.groupby('payment_method')['returned'].agg(['count', 'mean']).reset_index()
    pm_stats['return_rate_pct'] = (pm_stats['mean'] * 100).round(1)
    pm_stats = pm_stats.sort_values(by='return_rate_pct', ascending=False)
 
    plt.figure(figsize=(8, 5))
    bars = plt.bar(pm_stats['payment_method'], pm_stats['return_rate_pct'], color=['#d9534f', '#5bc0de', '#428bca'])
 
    plt.title('COD Returns at 44.4% — 3x Card', fontsize=14, fontweight='bold', pad=15)
    plt.xlabel('Payment Method', fontsize=11)
    plt.ylabel('Return Rate (%)', fontsize=11)
    plt.ylim(0, 55)
 
    for bar in bars:
        yval = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2.0, yval + 1.5, f"{yval:.1f}%", ha='center', va='bottom', fontsize=11, fontweight='bold')
 
    plt.tight_layout()
    plt.savefig('visualizations/return_rate_by_payment.png', dpi=300)
    plt.close()
    print("Saved visualizations/return_rate_by_payment.png")

    # -------------------------------------------------------------------------
    # Visualization 2: Monthly Revenue Trend (Outlier-Corrected)
    # -------------------------------------------------------------------------
    q1 = merged['quantity'].quantile(0.25)
    q3 = merged['quantity'].quantile(0.75)
    iqr = q3 - q1
    upper_bound = q3 + 1.5 * iqr
 
    merged_filtered = merged[merged['quantity'] <= upper_bound].copy()
    merged_filtered['year_month'] = pd.to_datetime(merged_filtered['order_date'], format='%d-%m-%Y').dt.to_period('M').astype(str)
 
    monthly_rev = merged_filtered.groupby('year_month')['order_value'].sum().reset_index()
 
    plt.figure(figsize=(9, 5))
    plt.plot(monthly_rev['year_month'], monthly_rev['order_value'], marker='o', linewidth=2.5, color='#2e6da4')
 
    plt.title('Outlier-Corrected Revenue Trend — Peak in March 2026', fontsize=14, fontweight='bold', pad=15)
    plt.xlabel('Month', fontsize=11)
    plt.ylabel('Total Order Value (INR)', fontsize=11)
    plt.grid(True, linestyle='--', alpha=0.6)
 
    for i, txt in enumerate(monthly_rev['order_value']):
        plt.annotate(f"₹{txt:,.2f}", (monthly_rev['year_month'][i], monthly_rev['order_value'][i]),
                     textcoords="offset points", xytext=(0, 10), ha='center', fontsize=9, fontweight='bold')
 
    plt.tight_layout()
    plt.savefig('visualizations/monthly_revenue_trend.png', dpi=300)
    plt.close()
    print("Saved visualizations/monthly_revenue_trend.png")

if __name__ == '__main__':
    generate_visualizations()
