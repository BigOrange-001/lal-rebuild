"""Plot exported final-config chapter curves with a Chinese display font."""
import argparse
import json
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties
from matplotlib.ticker import FuncFormatter, LogLocator


def units(value, _pos=None):
    if value >= 100_000_000:
        return f'{value / 100_000_000:.2f}'.rstrip('0').rstrip('.') + '亿'
    if value >= 10_000:
        return f'{value / 10_000:.2f}'.rstrip('0').rstrip('.') + '万'
    return f'{value:g}'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('data', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    data = json.loads(args.data.read_text(encoding='utf8'))
    font = FontProperties(fname='C:/Windows/Fonts/msyh.ttc')
    plt.rcParams.update({'font.family': font.get_name(), 'axes.unicode_minus': False,
                         'font.size': 12, 'axes.spines.top': False, 'axes.spines.right': False})
    rows = data['curves']
    x = [r['chapter'] for r in rows]
    normal = [r['normal'] for r in rows]
    elite = [r['elite'] for r in rows]
    blue, orange, ink = '#087FAD', '#D96B24', '#182F45'
    fig = plt.figure(figsize=(16, 9.6), facecolor='#F7FAFC')
    fig.text(.065, .94, '主线推荐战力曲线', fontsize=25, weight='bold', color=ink)
    fig.text(.065, .895, '按章节线性映射塔层 · 以每章末关为锚点 · 章内保留原有强弱关系',
             fontsize=12, color='#52677A')
    ax = fig.add_axes([.075, .30, .58, .52], facecolor='white')
    ax.axvspan(1, 5, color='#E9EFF4', alpha=.8)
    ax.plot(x, normal, color=blue, linewidth=3, label='普通主线', zorder=3)
    ax.plot(x, elite, color=orange, linewidth=3, label='精英主线', zorder=3)
    ax.scatter([1, 6, 30, 30], [elite[0], normal[5], normal[-1], elite[-1]],
               color=[orange, blue, blue, orange], s=55, edgecolors='white', zorder=5)
    ax.set_yscale('log')
    ax.set_xlim(1, 31)
    ax.set_ylim(4_000, 250_000_000)
    ax.set_xticks([1, 5, 6, 10, 15, 20, 25, 30])
    ax.yaxis.set_major_locator(LogLocator(base=10))
    ax.yaxis.set_major_formatter(FuncFormatter(units))
    ax.grid(axis='y', which='major', color='#DFE7ED', linewidth=.9)
    ax.set_xlabel('章节', labelpad=12)
    ax.set_ylabel('推荐战力（对数刻度）', labelpad=12)
    ax.text(3, 200_000, '普通1—5章\n逐步提升至2万', ha='center', color='#687E90', fontsize=10)
    ax.legend(loc='upper left', frameon=False, ncol=2)
    ax.annotate('普通30章 → 塔80层\n' + units(normal[-1]), (30, normal[-1]),
                xytext=(-12, -85), textcoords='offset points', ha='right', color=blue, fontsize=11)
    ax.annotate('精英30章 → 塔125层\n' + units(elite[-1]), (30, elite[-1]),
                xytext=(-12, 10), textcoords='offset points', ha='right', color=orange, fontsize=11)
    small = fig.add_axes([.735, .50, .215, .32], facecolor='white')
    small.plot(x, normal, color=blue, linewidth=2)
    small.plot(x, elite, color=orange, linewidth=2)
    small.set_xlim(1, 30)
    small.set_ylim(0, 150_000_000)
    small.set_xticks([1, 10, 20, 30])
    small.set_yticks([0, 50_000_000, 100_000_000, 150_000_000])
    small.yaxis.set_major_formatter(FuncFormatter(units))
    small.grid(axis='y', color='#DFE7ED')
    small.tick_params(labelsize=9)
    small.set_title('同一数据的线性刻度', fontsize=12, loc='left', pad=15, color=ink)
    fig.text(.735, .435, '普通：6—30章 → 塔10—80层\n精英：1—30章 → 塔10—125层',
             color=ink, fontsize=11, linespacing=1.9)
    table_rows = [rows[i-1] for i in (1, 5, 6, 10, 15, 20, 25, 30)]
    # Compact horizontal checkpoint table below both plots.
    table_ax = fig.add_axes([.075, .055, .875, .15])
    table_ax.axis('off')
    contents = [['章节'] + [str(r['chapter']) for r in table_rows],
                ['普通'] + [units(r['normal']) for r in table_rows],
                ['精英'] + [units(r['elite']) for r in table_rows]]
    for line in contents[1:]:
        for i, value in enumerate(line[1:], 1):
            n = table_rows[i-1]['normal' if line[0] == '普通' else 'elite']
            line[i] = f'{n / 100_000_000:.2f}亿' if n >= 100_000_000 else f'{n / 10000:.2f}万'
    table = table_ax.table(cellText=contents, cellLoc='center', loc='center', bbox=[0, 0, 1, 1])
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    for (r, c), cell in table.get_celld().items():
        cell.set_edgecolor('#E2EAF0')
        cell.set_facecolor('#E9F0F5' if r == 0 else 'white')
        cell.set_text_props(color=ink if r == 0 or c == 0 else (blue if r == 1 else orange))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=160, facecolor=fig.get_facecolor())
    fig.savefig(args.output.with_suffix('.svg'), facecolor=fig.get_facecolor())
    plt.close(fig)


if __name__ == '__main__':
    main()
