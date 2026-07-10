// ==UserScript==
// @name         lazyfisher辅助增强OL
// @namespace    https://lazyfisher.toogle.club/
// @version      0.3.1
// @description  lazyfisher辅助增强-Pro（功能模块可通过菜单开关控制）
// @author       天雨灵泽
// @match        *://toogle.club:36018/*
// @match        *://lazyfisher.toogle.club/*
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_registerMenuCommand
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function() {
    'use strict';

// ===== 在线加载 FISH_DATABASE =====
var FISH_DATABASE = [];
window.__fishDbReady = false;
window.__fishDbCallbacks = [];
window.__onFishDbReady = function(fn) {
    if (window.__fishDbReady) fn();
    else window.__fishDbCallbacks.push(fn);
};
GM_xmlhttpRequest({
    method: 'GET',
    url: 'https://raw.githubusercontent.com/lmld-6/lazyfisher.toogle.club.data/refs/heads/main/data_fish',
    onload: function(r) {
        if (r.status === 200) {
            var data = JSON.parse(r.responseText);
            FISH_DATABASE.push(...data);
        }
        window.__fishDbReady = true;
        window.__fishDbCallbacks.forEach(function(fn) { fn(); });
        window.__fishDbCallbacks = [];
    },
    onerror: function() {
        window.__fishDbReady = true;
        window.__fishDbCallbacks.forEach(function(fn) { fn(); });
        window.__fishDbCallbacks = [];
    }
});
// ===== 在线加载 HOOK_STRENGTH_DATA =====
var HOOK_STRENGTH_DATA = [];
window.__hookStrengthReady = false;
window.__hookStrengthCallbacks = [];
window.__onHookStrengthReady = function(fn) {
    if (window.__hookStrengthReady) fn();
    else window.__hookStrengthCallbacks.push(fn);
};
GM_xmlhttpRequest({
    method: 'GET',
    url: 'https://raw.githubusercontent.com/lmld-6/lazyfisher.toogle.club.data/refs/heads/main/HOOK_STRENGTH_DATA',
    onload: function(r) {
        if (r.status === 200) {
            var data = JSON.parse(r.responseText);
            HOOK_STRENGTH_DATA.push(...data);
        }
        window.__hookStrengthReady = true;
        window.__hookStrengthCallbacks.forEach(function(fn) { fn(); });
        window.__hookStrengthCallbacks = [];
    },
    onerror: function() {
        window.__hookStrengthReady = true;
        window.__hookStrengthCallbacks.forEach(function(fn) { fn(); });
        window.__hookStrengthCallbacks = [];
    }
});
// ===== 在线加载 ITEM_DATABASE =====
var ITEM_DATABASE = [];
window.__itemDbReady = false;
window.__itemDbCallbacks = [];
window.__onItemDbReady = function(fn) {
    if (window.__itemDbReady) fn();
    else window.__itemDbCallbacks.push(fn);
};
GM_xmlhttpRequest({
    method: 'GET',
    url: 'https://raw.githubusercontent.com/lmld-6/lazyfisher.toogle.club.data/refs/heads/main/ITEM_DATABASE',
    onload: function(r) {
        if (r.status === 200) {
            var data = JSON.parse(r.responseText);
            // 如果是对象，直接赋值；如果是数组，转为对象
            if (Array.isArray(data)) {
                // 数组转对象，用 id 做 key
                var obj = {};
                data.forEach(function(item) {
                    obj[item.id] = item;
                });
                ITEM_DATABASE = obj;
            } else {
                ITEM_DATABASE = data;
            }
            window.ITEM_DATABASE = ITEM_DATABASE;
        }
        window.__itemDbReady = true;
        window.__itemDbCallbacks.forEach(function(fn) { fn(); });
        window.__itemDbCallbacks = [];
    },
    onerror: function() {
        window.__itemDbReady = true;
        window.__itemDbCallbacks.forEach(function(fn) { fn(); });
        window.__itemDbCallbacks = [];
    }
});
// ============================================================
// 功能开关管理 - 纯浮动按钮版 (v0.2)
// ============================================================

const FEATURES = [
    { id: 'lureSoftness', name: '路亚软竿惩罚系数' },
    { id: 'fishSort', name: '区域探查鱼群排序' },
    { id: 'boatSort', name: '可上船只列表排序' },
    { id: 'waterLayer', name: '鱼群水层显示' },
    { id: 'fishLogColor', name: '钓鱼日志染色' },
    { id: 'fishStaminaUI', name: '鱼体力UI增强' },
    { id: 'catchInterval', name: '鱼口时间计算' },
    { id: 'dynamicBorder', name: '实时状态动态边框' },
    { id: 'reelEnhance', name: '渔轮装备参数增强' },
    { id: 'specializationSim', name: '专精模拟器' },
    { id: 'shopCardEnhance', name: '商店渔轮数增强' },
    { id: 'assemblySim', name: '装配台模拟器' },
    { id: 'hookStrength', name: '钩子拉力显示' },
    { id: 'fishCardGradeColor', name: '鱼获卡片背景染色' },
    { id: 'fishCardGlow', name: '鱼获卡片动态辉光' },
    { id: 'challengeFishInfo', name: '高难挑战鱼种资料' },
    { id: 'realtimeChart', name: '钓鱼实时波动图' },
    { id: 'fishWeightGlow', name: '区域鱼获重量光晕' },
    { id: 'sortChallenges', name: '委托高难排序' },
    { id: 'weeklyTarget', name: '本周目标鱼场地' },
    { id: 'specializationSummary', name: '专精加成汇总' },
    { id: 'fishValuePerKg', name: '单位重量价值' },
    { id: 'rankingStyle', name: '排行榜美化' },
    { id: 'catchPlate', name: '上鱼卡片美化' },
    { id: 'catchSummary', name: '上鱼记录统计' },
    { id: 'intervalTrendChart', name: '口数趋势图' },
    { id: 'boatMemberSort', name: '船上成员排序' },
    { id: 'EquipmentWeaknessAnalyzer', name: '装备状态' },
    { id: 'HideLoginIdentity', name: '隐藏ID' },
    { id: 'ItemCardEnhance', name: '商店饵显示增强' }
];

const SCRIPT_VERSION = '0.3.1';

function isEnabled(featureId) {
    var val = GM_getValue('feat_' + featureId);
    return val !== undefined ? val : true;
}

function setEnabled(featureId, enabled) {
    GM_setValue('feat_' + featureId, enabled);
}

function toggleFeature(featureId) {
    var enabled = isEnabled(featureId);
    setEnabled(featureId, !enabled);
    alert('功能开关已更改，页面将刷新以应用设置。');
    location.reload();
}

function initFloatingPanel() {
    // 防止重复初始化
    if (document.getElementById('lazyfisher-toggle-btn')) return;

    // ============================================================
    // 样式注入
    // ============================================================
    var style = document.createElement('style');
    style.id = 'lazyfisher-floating-panel-style';
    style.textContent = [
        '#lazyfisher-toggle-btn {',
        '  position: fixed;',
        '  z-index: 99999;',
        '  width: 52px;',
        '  height: 52px;',
        '  border-radius: 50%;',
        '  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);',
        '  color: #e0e0e0;',
        '  font-size: 9px;',
        '  font-weight: bold;',
        '  text-align: center;',
        '  line-height: 52px;',
        '  cursor: grab;',
        '  user-select: none;',
        '  box-shadow: 0 4px 15px rgba(0,0,0,0.5), 0 0 20px rgba(100, 150, 255, 0.2);',
        '  border: 2px solid rgba(100, 150, 255, 0.4);',
        '  transition: box-shadow 0.3s, border-color 0.3s;',
        '  font-family: monospace;',
        '  letter-spacing: 1px;',
        '}',
        '#lazyfisher-toggle-btn:hover {',
        '  box-shadow: 0 6px 25px rgba(0,0,0,0.6), 0 0 30px rgba(100, 150, 255, 0.4);',
        '  border-color: rgba(100, 150, 255, 0.7);',
        '}',
        '#lazyfisher-toggle-btn:active {',
        '  cursor: grabbing;',
        '}',
        '#lazyfisher-toggle-btn.panel-open {',
        '  cursor: pointer;',
        '  opacity: 0;',
        '  pointer-events: none;',
        '}',
        '#lazyfisher-panel {',
        '  position: fixed;',
        '  z-index: 99998;',
        '  width: 300px;',
        '  max-height: 70vh;',
        '  background: rgba(20, 20, 40, 0.95);',
        '  border-radius: 12px;',
        '  box-shadow: 0 8px 32px rgba(0,0,0,0.6), 0 0 40px rgba(100, 150, 255, 0.15);',
        '  border: 1px solid rgba(100, 150, 255, 0.3);',
        '  display: none;',
        '  flex-direction: column;',
        '  overflow: hidden;',
        '  font-family: "Segoe UI", sans-serif;',
        '}',
        '#lazyfisher-panel.visible {',
        '  display: flex;',
        '}',
        '#lazyfisher-panel-header {',
        '  display: flex;',
        '  justify-content: space-between;',
        '  align-items: center;',
        '  padding: 12px 16px;',
        '  background: rgba(0,0,0,0.3);',
        '  border-bottom: 1px solid rgba(100, 150, 255, 0.2);',
        '  cursor: grab;',
        '  user-select: none;',
        '}',
        '#lazyfisher-panel-header:active {',
        '  cursor: grabbing;',
        '}',
        '#lazyfisher-panel-title {',
        '  color: #a0c0ff;',
        '  font-size: 14px;',
        '  font-weight: bold;',
        '}',
        '#lazyfisher-panel-count {',
        '  color: #888;',
        '  font-size: 11px;',
        '}',
        '#lazyfisher-panel-close {',
        '  width: 24px;',
        '  height: 24px;',
        '  border-radius: 50%;',
        '  background: rgba(255,255,255,0.1);',
        '  color: #aaa;',
        '  border: none;',
        '  cursor: pointer;',
        '  font-size: 14px;',
        '  text-align: center;',
        '  line-height: 24px;',
        '  transition: all 0.2s;',
        '}',
        '#lazyfisher-panel-close:hover {',
        '  background: rgba(255,80,80,0.3);',
        '  color: #fff;',
        '}',
        '#lazyfisher-panel-body {',
        '  flex: 1;',
        '  overflow-y: auto;',
        '  padding: 8px;',
        '}',
        '#lazyfisher-panel-body::-webkit-scrollbar {',
        '  width: 4px;',
        '}',
        '#lazyfisher-panel-body::-webkit-scrollbar-thumb {',
        '  background: rgba(100, 150, 255, 0.3);',
        '  border-radius: 2px;',
        '}',
        '.lazyfisher-toggle-row {',
        '  display: flex;',
        '  justify-content: space-between;',
        '  align-items: center;',
        '  padding: 8px 12px;',
        '  margin: 2px 0;',
        '  border-radius: 6px;',
        '  transition: background 0.2s;',
        '  color: #ccc;',
        '  font-size: 13px;',
        '}',
        '.lazyfisher-toggle-row:hover {',
        '  background: rgba(255,255,255,0.05);',
        '}',
        '.lazyfisher-toggle-switch {',
        '  position: relative;',
        '  width: 40px;',
        '  height: 22px;',
        '  flex-shrink: 0;',
        '}',
        '.lazyfisher-toggle-switch input {',
        '  opacity: 0;',
        '  width: 0;',
        '  height: 0;',
        '  position: absolute;',
        '}',
        '.lazyfisher-toggle-slider {',
        '  position: absolute;',
        '  top: 0; left: 0; right: 0; bottom: 0;',
        '  background: #444;',
        '  border-radius: 22px;',
        '  cursor: pointer;',
        '  transition: background 0.3s;',
        '}',
        '.lazyfisher-toggle-slider::before {',
        '  content: "";',
        '  position: absolute;',
        '  width: 16px;',
        '  height: 16px;',
        '  left: 3px;',
        '  bottom: 3px;',
        '  background: #fff;',
        '  border-radius: 50%;',
        '  transition: transform 0.3s;',
        '}',
        '.lazyfisher-toggle-switch input:checked + .lazyfisher-toggle-slider {',
        '  background: #3a8fd4;',
        '}',
        '.lazyfisher-toggle-switch input:checked + .lazyfisher-toggle-slider::before {',
        '  transform: translateX(18px);',
        '}'
    ].join('\n');
    document.head.appendChild(style);

    // ============================================================
    // 创建浮动按钮
    // ============================================================
    var btn = document.createElement('div');
    btn.id = 'lazyfisher-toggle-btn';
    btn.textContent = 'v' + SCRIPT_VERSION;
    btn.title = '点击打开功能开关面板 | 拖拽移动';

    // ============================================================
    // 创建控制面板
    // ============================================================
    var panel = document.createElement('div');
    panel.id = 'lazyfisher-panel';

    var header = document.createElement('div');
    header.id = 'lazyfisher-panel-header';

    var titleSpan = document.createElement('span');
    titleSpan.id = 'lazyfisher-panel-title';
    titleSpan.textContent = '⚙ 功能开关';

    var countSpan = document.createElement('span');
    countSpan.id = 'lazyfisher-panel-count';

    var closeBtn = document.createElement('button');
    closeBtn.id = 'lazyfisher-panel-close';
    closeBtn.textContent = '✕';

    header.appendChild(titleSpan);
    header.appendChild(countSpan);
    header.appendChild(closeBtn);

    var body = document.createElement('div');
    body.id = 'lazyfisher-panel-body';

    panel.appendChild(header);
    panel.appendChild(body);

    // ============================================================
    // 构建开关行
    // ============================================================
    function buildToggleRows() {
        body.innerHTML = '';
        for (var i = 0; i < FEATURES.length; i++) {
            var f = FEATURES[i];
            var row = document.createElement('div');
            row.className = 'lazyfisher-toggle-row';

            var nameSpan = document.createElement('span');
            nameSpan.textContent = f.name;

            var label = document.createElement('label');
            label.className = 'lazyfisher-toggle-switch';

            var checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.checked = isEnabled(f.id);
            checkbox.setAttribute('data-feature', f.id);

            var slider = document.createElement('span');
            slider.className = 'lazyfisher-toggle-slider';

            label.appendChild(checkbox);
            label.appendChild(slider);
            row.appendChild(nameSpan);
            row.appendChild(label);
            body.appendChild(row);
        }

        // 绑定事件
        var checkboxes = body.querySelectorAll('input[type="checkbox"]');
        for (var j = 0; j < checkboxes.length; j++) {
            checkboxes[j].addEventListener('change', function() {
                toggleFeature(this.getAttribute('data-feature'));
            });
        }
    }

    buildToggleRows();

    document.body.appendChild(btn);
    document.body.appendChild(panel);

    // ============================================================
    // 更新计数
    // ============================================================
    function updateCount() {
        var total = FEATURES.length;
        var onCount = 0;
        for (var i = 0; i < FEATURES.length; i++) {
            if (isEnabled(FEATURES[i].id)) onCount++;
        }
        countSpan.textContent = onCount + '/' + total + ' ON';
    }
    updateCount();

    // ============================================================
    // 拖拽功能
    // ============================================================
    function makeDraggable(el, onClick) {
        var dragging = false;
        var startX, startY, origLeft, origTop;

        el.addEventListener('mousedown', function(e) {
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'BUTTON' || e.target.closest('button')) {
                return;
            }
            e.preventDefault();
            dragging = true;
            startX = e.clientX;
            startY = e.clientY;
            origLeft = el.offsetLeft;
            origTop = el.offsetTop;
            el.style.transition = 'none';
        });

        document.addEventListener('mousemove', function(e) {
            if (!dragging) return;
            el.style.left = (origLeft + e.clientX - startX) + 'px';
            el.style.top = (origTop + e.clientY - startY) + 'px';
        });

        document.addEventListener('mouseup', function(e) {
            if (!dragging) return;
            dragging = false;
            el.style.transition = '';
            var dist = Math.abs(e.clientX - startX) + Math.abs(e.clientY - startY);
            if (dist < 5 && onClick) {
                onClick();
            }
        });
    }

    // 面板通过标题栏拖拽
    makeDraggable(panel, null);

    // ============================================================
    // 打开/关闭面板
    // ============================================================
    function openPanel() {
        buildToggleRows();
        updateCount();

        var btnRect = btn.getBoundingClientRect();
        var panelW = 300;
        var panelH = Math.min(window.innerHeight * 0.7, 500);

        var left = btnRect.left;
        var top = btnRect.bottom + 8;

        if (left + panelW > window.innerWidth - 10) {
            left = window.innerWidth - panelW - 10;
        }
        if (top + panelH > window.innerHeight - 10) {
            top = btnRect.top - panelH - 8;
        }
        if (left < 10) left = 10;
        if (top < 10) top = 10;

        panel.style.left = left + 'px';
        panel.style.top = top + 'px';
        panel.classList.add('visible');
        btn.classList.add('panel-open');
    }

    function closePanel() {
        panel.classList.remove('visible');
        btn.classList.remove('panel-open');
    }

    // 按钮点击打开面板
    makeDraggable(btn, function() {
        openPanel();
    });

    // 关闭按钮
    closeBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        closePanel();
    });

    // 点击面板外部关闭
    document.addEventListener('click', function(e) {
        if (panel.classList.contains('visible') &&
            !panel.contains(e.target) &&
            !btn.contains(e.target)) {
            closePanel();
        }
    });

    // ============================================================
    // 初始位置（右下角）
    // ============================================================
    btn.style.right = '20px';
    btn.style.bottom = '80px';

    // 等待布局完成后计算实际位置
    setTimeout(function() {
        var rect = btn.getBoundingClientRect();
        btn.style.left = rect.left + 'px';
        btn.style.top = rect.top + 'px';
        btn.style.right = 'auto';
        btn.style.bottom = 'auto';
    }, 100);

    console.log('[功能开关面板] 已启动 | 版本 v' + SCRIPT_VERSION + ' | ' + FEATURES.length + ' 个功能');
}

// ============================================================
// 启动
// ============================================================
initFloatingPanel();

// ============================================================
// 1.路亚软竿惩罚系数模块
function initLureSoftness() {
        (function LureSoftnessModule() {
            const CONFIG = {
                H_TARGETS: {
                    'bottom_hop': 7.2,
                    'mid_twitch': 8.0
                },
                CHECK_INTERVAL_MS: 500,
                PANEL_ID: 'rf4-lure-penalty-panel',
            };
            function extractRodHardness() {
                const slotTitles = document.querySelectorAll('.loadout-slot-title');
                for (const title of slotTitles) {
                    if (title.textContent.includes('鱼竿')) {
                        const rodSlot = title.closest('.loadout-slot');
                        if (!rodSlot) return null;
                        const stats = rodSlot.querySelectorAll('.loadout-summary-stats span');
                        for (const stat of stats) {
                            if (stat.textContent.includes('硬度')) {
                                const match = stat.textContent.match(/[\d.]+/);
                                return match ? parseFloat(match[0]) : null;
                            }
                        }
                    }
                }
                return null;
            }
            function extractCurrentAction() {
                const controlSummary = document.querySelector('.loadout-control-summary');
                if (!controlSummary) return null;
                const spans = controlSummary.querySelectorAll('span');
                for (const span of spans) {
                    const text = span.textContent.trim();
                    if (text.includes('底层跳动')) return 'bottom_hop';
                    if (text.includes('中层抽动')) return 'mid_twitch';
                }
                return null;
            }
            function calculatePenalty(action, hardness) {
                if (!action || hardness === null || isNaN(hardness)) return null;
                const hTarget = CONFIG.H_TARGETS[action];
                if (hTarget <= 4.0 || hardness <= 4.0) return null;
                const rhoSoft = Math.max(0, Math.min(1, (hTarget - hardness) / (hTarget - 4.0)));
                return Math.max(0.65, Math.min(1.0, 1 - 0.35 * rhoSoft));
            }
            function getOrCreatePanel() {
                let panel = document.getElementById(CONFIG.PANEL_ID);
                if (panel) return panel;
                const summaryNode = document.querySelector('.equipment-selection-summary');
                if (!summaryNode) return null;
                panel = document.createElement('div');
                panel.id = CONFIG.PANEL_ID;
                panel.className = 'equipment-selection-summary';
                panel.innerHTML =
                    `<div class="equipment-selection-summary-block">
                        <div class="text-sm text-muted">软竿惩罚</div>
                        <div class="equipment-selection-summary-value" id="rf4-gamma">--</div>
                    </div>
                    <div class="equipment-selection-summary-block">
                        <div class="text-sm text-muted">状态</div>
                        <div class="equipment-selection-summary-value" id="rf4-status">等待数据</div>
                    </div>`;
                summaryNode.parentNode.insertBefore(panel, summaryNode.nextSibling);
                return panel;
            }
            function updateUI(gamma) {
                const panel = getOrCreatePanel();
                if (!panel) return;
                const valEl = document.getElementById('rf4-gamma');
                const stEl = document.getElementById('rf4-status');
                if (gamma === null) {
                    panel.style.display = 'none';
                    return;
                }
                panel.style.display = '';
                valEl.textContent = gamma.toFixed(2);
                valEl.style.color = '';
                stEl.style.color = '';
                if (gamma === 1.0) {
                    stEl.textContent = '无惩罚';
                } else if (gamma >= 0.8) {
                    stEl.textContent = '轻微惩罚';
                    valEl.style.color = '#f0ad4e';
                } else if (gamma >= 0.65) {
                    stEl.textContent = '严重惩罚';
                    valEl.style.color = '#d9534f';
                } else {
                    stEl.textContent = '上限惩罚';
                    valEl.style.color = '#d9534f';
                }
            }
            let lastAction = null, lastHardness = null;
            function tick() {
                const action = extractCurrentAction();
                const hardness = extractRodHardness();
                if (action !== lastAction || hardness !== lastHardness) {
                    lastAction = action;
                    lastHardness = hardness;
                    updateUI(calculatePenalty(action, hardness));
                }
            }
            setTimeout(() => { tick(); setInterval(tick, CONFIG.CHECK_INTERVAL_MS); }, 1000);
        })();
    }
// 2.区域探查鱼群排序
function initFishSort() {
    (function() {
        'use strict';

        const SORT_MODES = {
            WEIGHT_DESC:   'weight_desc',
            WEIGHT_ASC:    'weight_asc',
            WATER_LAYER:   'water_layer',
            BAIT_TYPE:     'bait_type',
            LURE_TYPE:     'lure_type',
        };

        const SORT_MODE_LABELS = {
            [SORT_MODES.WEIGHT_DESC]:  '重量▼',
            [SORT_MODES.WEIGHT_ASC]:   '重量▲',
            [SORT_MODES.WATER_LAYER]:  '水层',
            [SORT_MODES.BAIT_TYPE]:    '真饵',
            [SORT_MODES.LURE_TYPE]:    '拟饵',
        };

        const WATER_LAYER_ORDER = { '上层': 0, '中层': 1, '下层': 2 };
        const LOCK_POSITION = { TOP: 'top', BOTTOM: 'bottom' };
        const STORAGE_KEY = 'fish_sorter_prefs';

        // 深海夜幕主题配色
const THEME = {
    panelBg:          'rgba(248, 250, 252, 0.75)',
    panelBorder:      'rgba(56, 189, 248, 0.25)',
    labelColor:       '#334155',
    btnDefaultBg:     'rgba(241, 245, 249, 0.6)',
    btnDefaultColor:  '#334155',
    btnDefaultBorder: 'rgba(148, 163, 184, 0.5)',
    btnActiveBg:      '#1e40af',
    btnActiveColor:   '#ffffff',
    btnActiveBorder:  '#1e40af',
    sepColor:         'rgba(148, 163, 184, 0.4)',
};

        class SortPrefsStore {
            static load() {
                try {
                    const raw = localStorage.getItem(STORAGE_KEY);
                    if (raw) return JSON.parse(raw);
                } catch (e) {}
                return { sortMode: SORT_MODES.WEIGHT_DESC, lockPosition: LOCK_POSITION.BOTTOM };
            }
            static save(prefs) {
                try { localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs)); } catch (e) {}
            }
        }

        class RegionFishSorter {
            constructor() {
                this.prefs = SortPrefsStore.load();
                this.panelEl = null;
                this._justSorted = false;
                this.fishLookup = this._buildLookup();
            }

            _buildLookup() {
                const table = {};
                if (typeof FISH_DATABASE !== 'undefined') {
                    if (FISH_DATABASE.content && Array.isArray(FISH_DATABASE.content)) {
                        FISH_DATABASE.content.forEach(fish => {
                            if (fish.name) table[fish.name] = fish.details || {};
                        });
                    } else if (Array.isArray(FISH_DATABASE)) {
                        FISH_DATABASE.forEach(fish => {
                            if (fish['名称']) table[fish['名称']] = fish['详情'] || {};
                        });
                    }
                }
                return table;
            }

            _getInfo(fishName) { return this.fishLookup[fishName] || {}; }

            isLocked(card) {
                const btn = card.querySelector('.region-fish-lock-button');
                return btn && btn.classList.contains('region-fish-lock-button--locked');
            }

            getFishName(card) {
                const nameEl = card.querySelector('.item-name');
                if (!nameEl) return '';
                let name = '';
                for (const node of nameEl.childNodes) {
                    if (node.nodeType === 3) name += node.textContent;
                }
                return name.trim();
            }

            extractWeight(card) {
                try {
                    const els = card.querySelectorAll('.text-xs.text-muted');
                    if (els.length === 0) return 0;
                    const text = els[els.length - 1].textContent.trim().replace(/[^0-9.]/g, '');
                    const w = parseFloat(text);
                    return isNaN(w) ? 0 : w;
                } catch (e) { return 0; }
            }

            sort(cards, mode) {
                const fishData = cards.map(card => {
                    const name = this.getFishName(card);
                    const info = this._getInfo(name);
                    return {
                        card, name,
                        weight: this.extractWeight(card),
                        waterLayer: info['水层'] || null,
                        bait: info['偏好饵料'] || null,
                        lure: info['偏好拟饵'] || null,
                    };
                });

                switch (mode) {
                    case SORT_MODES.WEIGHT_DESC:
                        fishData.sort((a, b) => b.weight - a.weight);
                        break;
                    case SORT_MODES.WEIGHT_ASC:
                        fishData.sort((a, b) => a.weight - b.weight);
                        break;
                    case SORT_MODES.WATER_LAYER:
                        fishData.sort((a, b) => {
                            const la = WATER_LAYER_ORDER[a.waterLayer] ?? 99;
                            const lb = WATER_LAYER_ORDER[b.waterLayer] ?? 99;
                            if (la !== lb) return la - lb;
                            return b.weight - a.weight;
                        });
                        break;
                    case SORT_MODES.BAIT_TYPE:
                        fishData.sort((a, b) => {
                            const ba = a.bait || 'zzz', bb = b.bait || 'zzz';
                            if (ba !== bb) return ba.localeCompare(bb);
                            return b.weight - a.weight;
                        });
                        break;
                    case SORT_MODES.LURE_TYPE:
                        fishData.sort((a, b) => {
                            const la = a.lure || 'zzz', lb = b.lure || 'zzz';
                            if (la !== lb) return la.localeCompare(lb);
                            return b.weight - a.weight;
                        });
                        break;
                    default:
                        fishData.sort((a, b) => b.weight - a.weight);
                }
                return fishData;
            }

            execute() {
                const grid = document.querySelector('.region-fish-grid');
                if (!grid) return;
                const cards = Array.from(grid.querySelectorAll('.region-fish-card'));
                if (cards.length === 0) return;

                this.markAllLockedNames(cards);

                const locked = [], unlocked = [];
                cards.forEach(card => {
                    if (this.isLocked(card)) locked.push(card);
                    else unlocked.push(card);
                });

                const sortedUnlocked = this.sort(unlocked, this.prefs.sortMode);
                const lockPos = this.prefs.lockPosition;

                if (lockPos === LOCK_POSITION.TOP) {
                    locked.forEach(card => grid.appendChild(card));
                    sortedUnlocked.forEach(({ card }) => grid.appendChild(card));
                } else {
                    sortedUnlocked.forEach(({ card }) => grid.appendChild(card));
                    locked.forEach(card => grid.appendChild(card));
                }

                this._justSorted = true;
                setTimeout(() => { this._justSorted = false; }, 500);
            }

            markLockedName(card) {
                const nameEl = card.querySelector('.item-name');
                if (!nameEl) return;
                if (this.isLocked(card)) {
                    nameEl.style.color = '#ef4444';
                    nameEl.style.fontWeight = 'bold';
                } else {
                    nameEl.style.color = '';
                    nameEl.style.fontWeight = '';
                }
            }

            markAllLockedNames(cards) { cards.forEach(c => this.markLockedName(c)); }

            isDataReady() {
                const cards = document.querySelectorAll('.region-fish-card');
                if (cards.length === 0) return false;
                for (const card of cards) {
                    if (this.extractWeight(card) > 0) return true;
                }
                return false;
            }

            createPanel() {
                if (this.panelEl) return this.panelEl;

                const panel = document.createElement('div');
                panel.id = 'fish-sort-panel';
                panel.style.cssText = `
                    display:flex;flex-wrap:wrap;align-items:center;gap:4px;
                    margin-bottom:6px;padding:6px 8px;
                    background:${THEME.panelBg};
                    border:1px solid ${THEME.panelBorder};
                    border-radius:6px;font-size:0.78em;
                `;

                const label = document.createElement('span');
                label.textContent = '排序:';
                label.style.cssText = `color:${THEME.labelColor};margin-right:2px;`;
                panel.appendChild(label);

                const makeBtn = (text, callback) => {
                    const btn = document.createElement('button');
                    btn.textContent = text;
                    btn.style.cssText = `
                        padding:2px 7px;
                        border:1px solid ${THEME.btnDefaultBorder};
                        border-radius:4px;
                        background:${THEME.btnDefaultBg};
                        color:${THEME.btnDefaultColor};
                        cursor:pointer;font-size:0.75em;white-space:nowrap;
                    `;
                    btn.addEventListener('click', callback);
                    panel.appendChild(btn);
                    return btn;
                };

                Object.entries(SORT_MODE_LABELS).forEach(([mode, txt]) => {
                    const btn = makeBtn(txt, () => this.setSortMode(mode));
                    btn.dataset.mode = mode;
                });

                const sep = document.createElement('span');
                sep.textContent = '|';
                sep.style.cssText = `color:${THEME.sepColor};margin:0 2px;`;
                panel.appendChild(sep);

                const lockLabel = document.createElement('span');
                lockLabel.textContent = '锁定:';
                lockLabel.style.cssText = `color:${THEME.labelColor};`;
                panel.appendChild(lockLabel);

                makeBtn('在上', () => this.setLockPosition(LOCK_POSITION.TOP));
                makeBtn('在下', () => this.setLockPosition(LOCK_POSITION.BOTTOM));

                this.panelEl = panel;
                this._highlightButtons();
                return panel;
            }

            _highlightButtons() {
                if (!this.panelEl) return;
                this.panelEl.querySelectorAll('button').forEach(btn => {
                    const mode = btn.dataset.mode;
                    const isActive =
                        (mode && mode === this.prefs.sortMode) ||
                        (btn.textContent === '在上' && this.prefs.lockPosition === LOCK_POSITION.TOP) ||
                        (btn.textContent === '在下' && this.prefs.lockPosition === LOCK_POSITION.BOTTOM);
                    if (isActive) {
                        btn.style.background = THEME.btnActiveBg;
                        btn.style.color = THEME.btnActiveColor;
                        btn.style.borderColor = THEME.btnActiveBorder;
                    } else {
                        btn.style.background = THEME.btnDefaultBg;
                        btn.style.color = THEME.btnDefaultColor;
                        btn.style.borderColor = THEME.btnDefaultBorder;
                    }
                });
            }

            setSortMode(mode) {
                if (this.prefs.sortMode === mode) return;
                this.prefs.sortMode = mode;
                SortPrefsStore.save(this.prefs);
                this._highlightButtons();
                this.execute();
            }

            setLockPosition(pos) {
                if (this.prefs.lockPosition === pos) return;
                this.prefs.lockPosition = pos;
                SortPrefsStore.save(this.prefs);
                this._highlightButtons();
                this.execute();
            }

            injectPanel() {
                const grid = document.querySelector('.region-fish-grid');
                if (!grid || document.getElementById('fish-sort-panel')) return;
                grid.parentNode.insertBefore(this.createPanel(), grid);
            }
        }

        function init() {
            const sorter = new RegionFishSorter();

            let retries = 0;
            function waitForData() {
                if (sorter.isDataReady()) {
                    sorter.injectPanel();
                    sorter.execute();
                    return;
                }
                if (++retries < 20) setTimeout(waitForData, 500);
                else { sorter.injectPanel(); sorter.execute(); }
            }
            waitForData();

            let timer = null;
            const observer = new MutationObserver((mutations) => {
                for (const m of mutations) {
                    if (m.type === 'attributes' && m.attributeName === 'class') {
                        if (m.target.classList.contains('region-fish-lock-button')) {
                            if (!sorter._justSorted) {
                                const card = m.target.closest('.region-fish-card');
                                if (card) sorter.markLockedName(card);
                            }
                            continue;
                        }
                    }
                    if (m.type === 'childList') {
                        const t = m.target;
                        if (t.classList && t.classList.contains('region-fish-grid')) {
                            clearTimeout(timer);
                            timer = setTimeout(() => {
                                if (sorter.isDataReady()) { sorter.injectPanel(); sorter.execute(); }
                            }, 600);
                            return;
                        }
                        for (const n of m.addedNodes) {
                            if (n.nodeType === 1 && (n.classList.contains('region-fish-card') || n.querySelector('.region-fish-card'))) {
                                clearTimeout(timer);
                                timer = setTimeout(() => {
                                    if (sorter.isDataReady()) { sorter.injectPanel(); sorter.execute(); }
                                }, 600);
                                return;
                            }
                        }
                    }
                }
            });

            observer.observe(document.body, {
                childList: true, subtree: true, attributes: true, attributeFilter: ['class']
            });

            console.log('[鱼群排序] 已启动（深海夜幕主题）');
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', init);
        } else {
            init();
        }
    })();
}
// 3.可上船只列表排序
function initBoatSort() {
        (function() {
            'use strict';
            class BoatSorter {
                static canBoard(card) {
                    const button = card.querySelector('button');
                    if (!button) return false;
                    if (button.hasAttribute('disabled')) return false;
                    if (button.textContent.trim() !== '上船') return false;
                    return true;
                }
                static getStateSignature() {
                    const cards = document.querySelectorAll('.card-list .card.item-card');
                    let boardable = 0;
                    let unboardable = 0;
                    cards.forEach(card => {
                        if (this.canBoard(card)) boardable++;
                        else unboardable++;
                    });
                    return `${boardable}|${unboardable}`;
                }
                static isDataReady() {
                    const cards = document.querySelectorAll('.card-list .card.item-card');
                    if (cards.length === 0) return false;
                    for (const card of cards) {
                        if (card.querySelector('button')) return true;
                    }
                    return false;
                }
                static isAlreadySorted() {
                    const list = document.querySelector('.card-list');
                    if (!list) return true;
                    const cards = Array.from(list.querySelectorAll('.card.item-card'));
                    let foundUnboardable = false;
                    for (const card of cards) {
                        if (this.canBoard(card)) {
                            if (foundUnboardable) return false;
                        } else {
                            foundUnboardable = true;
                        }
                    }
                    return true;
                }
                static sort() {
                    const list = document.querySelector('.card-list');
                    if (!list) return;
                    if (this.isAlreadySorted()) return;
                    const cards = Array.from(list.querySelectorAll('.card.item-card'));
                    const boardableCards = [];
                    const unboardableCards = [];
                    cards.forEach(card => {
                        if (this.canBoard(card)) {
                            boardableCards.push(card);
                        } else {
                            unboardableCards.push(card);
                        }
                    });
                    boardableCards.forEach(card => list.appendChild(card));
                    unboardableCards.forEach(card => list.appendChild(card));
                    console.log(`[船只排序] 已完成 - 可上船: ${boardableCards.length}, 不可上船: ${unboardableCards.length}`);
                }
            }
            function init() {
                let initialRetries = 0;
                const MAX_RETRIES = 20;
                const RETRY_DELAY = 500;
                function waitForData() {
                    if (BoatSorter.isDataReady()) {
                        BoatSorter.sort();
                        console.log('[船只排序] 首次排序完成');
                        return;
                    }
                    initialRetries++;
                    if (initialRetries < MAX_RETRIES) {
                        setTimeout(waitForData, RETRY_DELAY);
                    } else {
                        console.warn('[船只排序] 等待超时，强制执行');
                        BoatSorter.sort();
                    }
                }
                waitForData();
                let debounceTimer = null;
                const observer = new MutationObserver((mutations) => {
                    let shouldSort = false;
                    for (const mutation of mutations) {
                        if (mutation.type === 'attributes' && mutation.attributeName === 'disabled') {
                            if (mutation.target.nodeType === 1 && mutation.target.tagName === 'BUTTON') {
                                shouldSort = true;
                                break;
                            }
                        }
                        if (mutation.type === 'childList') {
                            const target = mutation.target;
                            if (target.nodeType === 1 && target.classList && target.classList.contains('card-list')) {
                                shouldSort = true;
                                break;
                            }
                            for (const node of mutation.addedNodes) {
                                if (node.nodeType === 1) {
                                    if (node.classList.contains('item-card') || node.querySelector('.item-card')) {
                                        shouldSort = true;
                                        break;
                                    }
                                    if (node.tagName === 'BUTTON' || node.querySelector('button')) {
                                        shouldSort = true;
                                        break;
                                    }
                                }
                            }
                            for (const node of mutation.removedNodes) {
                                if (node.nodeType === 1) {
                                    if (node.classList.contains('item-card') || node.querySelector('.item-card')) {
                                        shouldSort = true;
                                        break;
                                    }
                                }
                            }
                        }
                        if (mutation.type === 'characterData') {
                            const parent = mutation.target.parentNode;
                            if (parent && parent.nodeType === 1 && parent.tagName === 'BUTTON') {
                                shouldSort = true;
                                break;
                            }
                        }
                    }
                    if (shouldSort) {
                        clearTimeout(debounceTimer);
                        debounceTimer = setTimeout(() => {
                            if (BoatSorter.isDataReady()) {
                                BoatSorter.sort();
                            }
                        }, 300);
                    }
                });
                observer.observe(document.body, {
                    childList: true,
                    subtree: true,
                    attributes: true,
                    attributeFilter: ['disabled'],
                    characterData: true,
                });
                let lastSignature = '';
                const POLL_INTERVAL = 2000;
                function pollCheck() {
                    if (!BoatSorter.isDataReady()) return;
                    const currentSignature = BoatSorter.getStateSignature();
                    if (currentSignature !== lastSignature) {
                        lastSignature = currentSignature;
                        BoatSorter.sort();
                    }
                }
                setTimeout(() => {
                    lastSignature = BoatSorter.getStateSignature();
                }, 1000);
                setInterval(pollCheck, POLL_INTERVAL);
                console.log('[船只排序] 已启动（Observer + 轮询双保险）');
            }
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', init);
            } else {
                init();
            }
        })();
    }
// 4.鱼群水层显示
function initWaterLayer() {
    (function() {
        'use strict';

        // 钓鱼主题配色
        const WATER_LAYER_CONFIG = {
            '上层': { color: '#fff', bg: '#1E88E5', short: '上' },  // 海洋蓝
            '中层': { color: '#fff', bg: '#43A047', short: '中' },  // 水草绿
            '下层': { color: '#fff', bg: '#6D4C41', short: '下' },  // 礁石灰
            '表层': { color: '#fff', bg: '#039BE5', short: '表' },  // 浅海蓝
            '底层': { color: '#fff', bg: '#4E342E', short: '底' },  // 深海棕
        };

        const BAIT_SHORT = {
            '活小鱼': '活', '死小鱼': '死', '大整条饵鱼': '大',
            '小整条饵鱼': '小', '切块饵鱼': '切', '虾': '虾',
            '蟹': '蟹', '虫': '虫', '蛤': '蛤',
        };

        const LURE_SHORT = {
            '水面系': '水', '亮片': '亮', '米诺': '米',
            '铅头钩': '铅', '摇滚': '摇', '铁板': '铁',
            '软虫': '软', 'VIB': 'V',
        };

        // 钓鱼主题标签颜色
        const TAG_LAYER_BG = '#1565C0';   // 深海蓝（水层）
        const TAG_BAIT_BG = '#E65100';    // 鱼饵橙（饵料）
        const TAG_LURE_BG = '#2E7D32';    // 渔具绿（拟饵）

        function getBaitShort(bait) { return BAIT_SHORT[bait] || bait.charAt(0); }
        function getLureShort(lure) { return LURE_SHORT[lure] || lure.charAt(0); }

        class FishCardEnhancer {
            static buildLookupTable() {
                const table = {};
                if (typeof FISH_DATABASE !== 'undefined') {
                    const items = FISH_DATABASE.content || FISH_DATABASE;
                    if (Array.isArray(items)) {
                        items.forEach(fish => {
                            const name = fish.name || fish['名称'];
                            const details = fish.details || fish['详情'] || {};
                            if (name) table[name] = details;
                        });
                    }
                }
                return table;
            }

            static getLookupTable() {
                if (!this._lookupTable) this._lookupTable = this.buildLookupTable();
                return this._lookupTable;
            }

            static getFishInfo(fishName) {
                return this.getLookupTable()[fishName] || null;
            }

            static applyToCard(card) {
                const nameEl = card.querySelector('.item-name');
                if (!nameEl) return;
                const fishName = nameEl.textContent.trim();
                const info = this.getFishInfo(fishName);
                if (!info) return;
                if (card.querySelector('.fish-tag-row')) return;

                const hasLayer = info['水层'];
                const hasBait = info['偏好饵料'];
                const hasLure = info['偏好拟饵'];

                if (hasLayer || hasBait || hasLure) {
                    const row = document.createElement('div');
                    row.className = 'fish-tag-row';
                    row.style.cssText = 'display:block;margin-top:2px;line-height:1.4;';

                    if (hasLayer) {
                        const tag = document.createElement('span');
                        tag.textContent = hasLayer.charAt(0); // 取第一个字：上/中/下/表/底
                        tag.style.cssText = `display:inline-block;color:#fff;background:${TAG_LAYER_BG};font-size:0.65em;font-weight:700;padding:1px 5px;border-radius:3px;margin-right:3px;`;
                        tag.title = hasLayer; // 鼠标悬停显示完整名称
                        row.appendChild(tag);
                    }

                    if (hasBait) {
                        const tag = document.createElement('span');
                        tag.textContent = getBaitShort(hasBait);
                        tag.style.cssText = `display:inline-block;color:#fff;background:${TAG_BAIT_BG};font-size:0.65em;font-weight:700;padding:1px 5px;border-radius:3px;margin-right:3px;`;
                        tag.title = hasBait;
                        row.appendChild(tag);
                    }

                    if (hasLure) {
                        const tag = document.createElement('span');
                        tag.textContent = getLureShort(hasLure);
                        tag.style.cssText = `display:inline-block;color:#fff;background:${TAG_LURE_BG};font-size:0.65em;font-weight:700;padding:1px 5px;border-radius:3px;margin-right:3px;`;
                        tag.title = hasLure;
                        row.appendChild(tag);
                    }

                    nameEl.parentNode.insertBefore(row, nameEl.nextSibling);
                }
            }

            static applyAll() {
                document.querySelectorAll('.region-fish-card').forEach(card => this.applyToCard(card));
            }
        }

        function init() {
            let retries = 0;
            function wait() {
                const cards = document.querySelectorAll('.region-fish-card');
                if (cards.length > 0) {
                    const first = cards[0].querySelector('.item-name');
                    if (first && first.textContent.trim()) {
                        FishCardEnhancer.applyAll();
                        return;
                    }
                }
                if (++retries < 20) setTimeout(wait, 500);
                else FishCardEnhancer.applyAll();
            }
            wait();

            let timer = null;
            const observer = new MutationObserver((mutations) => {
                for (const m of mutations) {
                    if (m.type === 'childList') {
                        const t = m.target;
                        if (t.classList && t.classList.contains('region-fish-grid')) {
                            clearTimeout(timer);
                            timer = setTimeout(() => FishCardEnhancer.applyAll(), 400);
                            return;
                        }
                        for (const n of m.addedNodes) {
                            if (n.nodeType === 1 && (n.classList.contains('region-fish-card') || n.querySelector('.region-fish-card'))) {
                                clearTimeout(timer);
                                timer = setTimeout(() => FishCardEnhancer.applyAll(), 400);
                                return;
                            }
                        }
                    }
                }
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', init);
        } else {
            init();
        }
    })();
}
// 5.钓鱼日志染色
function initFishLogColor() {
        (function() {
            'use strict';
            if (!document.getElementById('fish-log-colors-style')) {
                const style = document.createElement('style');
                style.id = 'fish-log-colors-style';
                style.textContent = `
                    .gold-glow {
                        background: linear-gradient(90deg, #FFD700, #EF989A, #FFD700);
                        background-size: 200% 100%;
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                        background-clip: text;
                        animation: shimmer 2s ease-in-out infinite;
                        font-weight: bold;
                    }

                    .green-glow {
                        background: linear-gradient(90deg, #22C55E, #86EFAC, #22C55E);
                        background-size: 200% 100%;
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                        background-clip: text;
                        animation: shimmer 1.5s ease-in-out infinite;
                        font-weight: bold;
                    }

                    @keyframes shimmer {
                        0% { background-position: -200% 0; }
                        100% { background-position: 200% 0; }
                    }
                `;
                document.head.appendChild(style);
            }
            const colorRules = [
                { word: '鱼讯',   color: 'green-glow' },
                { word: '传说',   color: 'gold-glow' },
                { word: '不达标', color: '#A7B1BF' },
                { word: '达标',   color: '#22C55E' },
                { word: '罕见',   color: '#F2C77D' },
                { word: '稀有',   color: '#92B9F7' },
                { word: '脱钩逃脱', color: 'red' }
            ];
            function colorizeMessage(el) {
                if (el.dataset.colored) return;
                el.dataset.colored = '1';
                const text = el.textContent || '';
                for (const rule of colorRules) {
                    if (text.includes(rule.word)) {
                        if (rule.color === 'green-glow') {
                            el.classList.add('green-glow');
                        } else if (rule.color === 'gold-glow') {
                            el.classList.add('gold-glow');
                        } else {
                            el.style.color = rule.color;
                            el.style.fontWeight = 'bold';
                        }
                        break;
                    }
                }
            }
            function processLogs() {
                const logs = document.querySelectorAll('.fishing-log-message:not([data-colored])');
                logs.forEach(colorizeMessage);
            }
            function init() {
                const container = document.querySelector('.fishing-log-list')
                               || document.querySelector('.card.mb-md')
                               || document.body;
                if (!container) return;
                processLogs();
                const observer = new MutationObserver(() => {
                    processLogs();
                });
                observer.observe(container, { childList: true, subtree: true });
            }
            if (document.readyState === 'complete') {
                init();
            } else {
                window.addEventListener('DOMContentLoaded', init);
            }
        })();
    }
// 6.鱼口时间计算
function initCatchInterval() {
        (function() {
            'use strict';
            function calculateCatchIntervals() {
                const catchCards = document.querySelectorAll('.message-card--catch');
                if (catchCards.length < 2) return;
                document.querySelectorAll('.message-card--catch .catch-interval').forEach(el => el.remove());
                const catchTimes = [];
                catchCards.forEach(card => {
                    const timeElement = card.querySelector('.text-xs.text-muted');
                    if (timeElement) {
                        const timeStr = timeElement.childNodes[0]?.nodeValue?.trim();
                        if (timeStr) {
                            const time = parseCustomDate(timeStr);
                            if (time && !isNaN(time)) {
                                catchTimes.push({ time: time, timeElement: timeElement });
                            }
                        }
                    }
                });
                for (let i = 0; i < catchTimes.length - 1; i++) {
                    const currentItem = catchTimes[i];
                    const previousItem = catchTimes[i + 1];
                    const diffMs = Math.abs(currentItem.time - previousItem.time);
                    const diffMinutes = Math.round(diffMs / 1000 / 60);
                    const intervalSpan = document.createElement('span');
                    intervalSpan.className = 'catch-interval text-xs text-muted ml-sm';
                    intervalSpan.textContent = ` │ 鱼口: ${diffMinutes}分钟`;
                    currentItem.timeElement.appendChild(intervalSpan);
                }
            }
            function parseCustomDate(dateStr) {
                if (!dateStr) return null;
                const isoStr = dateStr.replace(/\//g, '-').replace(' ', 'T');
                return new Date(isoStr);
            }
            setTimeout(calculateCatchIntervals, 1000);
            const observer = new MutationObserver(function(mutations) {
                clearTimeout(window.catchIntervalTimer);
                window.catchIntervalTimer = setTimeout(calculateCatchIntervals, 300);
            });
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        })();
    }
// 7.渔轮装备参数增强
function initReelEnhance() {
    (function() {
        'use strict';
        function enhanceCard(card) {
            if (card.dataset.reelEnhanced) return;
            const statsContainer = card.querySelector('.loadout-slot-stats');
            if (!statsContainer) return;
            const gearSpan = [...statsContainer.querySelectorAll('span')].find(s => {
                const t = s.textContent;
                return t.includes('齿比') && /\d/.test(t);
            });
            const dragSpan = [...statsContainer.querySelectorAll('span')].find(s => {
                const t = s.textContent;
                return t.includes('最大摩擦力') && /\d/.test(t);
            });
            const speedSpan = [...statsContainer.querySelectorAll('span')].find(s => {
                const t = s.textContent;
                return t.includes('最大收线速度') && /\d/.test(t);
            });
            const dragMatch = dragSpan?.textContent.match(/最大摩擦力\s+([\d.]+)/);
            const speedMatch = speedSpan?.textContent.match(/最大收线速度\s+([\d.]+)/);
            const gearMatch = gearSpan?.textContent.match(/齿比\s+([\d.]+)/);
            if (dragSpan && !dragMatch) return;
            if (speedSpan && !speedMatch) return;
            if (gearSpan && !gearMatch) return;
            if (!dragMatch && !speedMatch) return;
            let lockValue = null;
            if (dragMatch) {
                lockValue = (parseFloat(dragMatch[1]) * 1.5).toFixed(1);
            }
            let lineSpeed = null;
            if (speedMatch && gearMatch) {
                const maxSpeed = parseFloat(speedMatch[1]);
                const gearRatio = parseFloat(gearMatch[1]);
                lineSpeed = ((gearRatio / 1.3) * (maxSpeed / 2.4)).toFixed(2);
            }
            if (lockValue !== null || lineSpeed !== null) {
                const combinedSpan = document.createElement('span');
                let html = '';
                if (lockValue !== null) {
                    html += '<span style="color:#64748B;font-weight:bold;">锁轮: ' + lockValue + '</span>';
                }
                if (lineSpeed !== null) {
                    if (lockValue !== null) html += ' <span style="color:var(--color-text-muted);">     </span> ';
                    html += '<span style="color:#64748B;font-weight:bold;">初始速度: ' + lineSpeed + '</span>';
                }
                combinedSpan.innerHTML = html;
                statsContainer.appendChild(combinedSpan);
            }
            card.dataset.reelEnhanced = '1';
        }
        function enhanceAll() {
            document.querySelectorAll('.loadout-slot').forEach(enhanceCard);
        }
        setTimeout(enhanceAll, 300);
        const observer = new MutationObserver(() => enhanceAll());
        observer.observe(document.body, {
            childList: true,
            subtree: true,
            characterData: true
        });
        console.log('[渔轮增强 v8] 单行显示，锁轮拉力+初始速度，公式: (齿轮/1.3)×(速度/2.4)');
    })();
}
// 8.商店卡片渔轮参数增强
function initShopCardEnhance() {
    (function() {
        'use strict';
        const OBSERVER_OPTIONS = { childList: true, subtree: true, characterData: true };
        function isPlaceholderText(text) {
            if (!text || text.trim() === '') return true;
            if (/加载|数据|请稍|\.\.\./.test(text)) return true;
            if (!/\d/.test(text)) return true;
            return false;
        }
        function findSpanWithData(container, keyword) {
            return [...container.querySelectorAll('span')].find(s => {
                const t = s.textContent;
                return t.includes(keyword) && !isPlaceholderText(t);
            });
        }
        function enhanceShopCard(card) {
            const metaContainer = card.querySelector('.shop-card-meta');
            if (!metaContainer) return;
            if (metaContainer.querySelector('.calc-result-bottom')) return;
            const gearSpan = findSpanWithData(metaContainer, '齿比');
            const dragSpan = findSpanWithData(metaContainer, '最大摩擦力');
            const speedSpan = findSpanWithData(metaContainer, '最大收线速度');
            const allText = metaContainer.textContent;
            if (allText.includes('齿比') && !gearSpan) return;
            if (allText.includes('最大摩擦力') && !dragSpan) return;
            if (allText.includes('最大收线速度') && !speedSpan) return;
            const dragMatch = dragSpan?.textContent.match(/最大摩擦力[\s:]*([\d.]+)/);
            const speedMatch = speedSpan?.textContent.match(/最大收线速度[\s:]*([\d.]+)/);
            const gearMatch = gearSpan?.textContent.match(/齿比[\s:]*([\d.]+)/);
            let lockValue = null;
            if (dragMatch) {
                lockValue = (parseFloat(dragMatch[1]) * 1.5).toFixed(1);
            }
            let lineSpeed = null;
            if (speedMatch && gearMatch) {
                const maxSpeed = parseFloat(speedMatch[1]);
                const gearRatio = parseFloat(gearMatch[1]);
                lineSpeed = ((gearRatio / 1.3) * (maxSpeed / 2.4)).toFixed(2);
            }
            if (lockValue === null && lineSpeed === null) return;
            const resultSpan = document.createElement('span');
            resultSpan.className = 'calc-result-bottom';
            let html = '';
            if (lockValue !== null) {
                html += '锁轮' + lockValue;
            }
            if (lineSpeed !== null) {
                if (lockValue !== null) html += '   ';
                html += '初始速度' + lineSpeed;
            }
            resultSpan.innerHTML = html;
            resultSpan.style.color = '#64748B';
            resultSpan.style.fontWeight = 'bold';
            metaContainer.appendChild(resultSpan);
        }
        function enhanceAll() {
            document.querySelectorAll('.shop-grid-card').forEach(enhanceShopCard);
        }
        setTimeout(enhanceAll, 500);
        const observer = new MutationObserver(() => enhanceAll());
        observer.observe(document.body, OBSERVER_OPTIONS);
        console.log('[商店卡片增强 v4] 颜色统一#64748B，公式: (齿轮/1.3)×(速度/2.4)');
    })();
}
// 9.装配台模拟器
function initAssemblySim() {
    (function() {
        'use strict';

        // ==================== 零件库 ====================
        const PART_LIBRARY = {
            "竿胚": [
                { id: "A_std_carbon_blank", name: "A线标准碳布竿胚", rarity: "史诗", attributes: { "最大张力": 44, "硬度": 8.6, "手感": 6.6 } },
                { id: "A_std_heavy_blank", name: "A线标准重载竿胚", rarity: "史诗", attributes: { "最大张力": 52, "硬度": 9.2, "手感": 5.8 } },
                { id: "A_enh_control_blank", name: "A线加强控线竿胚", rarity: "传说", attributes: { "最大张力": 68, "硬度": 10.2, "手感": 7.3 } },
                { id: "A_enh_torque_blank", name: "A线加强扭矩竿胚", rarity: "传说", attributes: { "最大张力": 78, "硬度": 11.0, "手感": 6.4 } },
                { id: "B_heavy_mainspine_blank", name: "B线重载主脊竿胚", rarity: "传说", attributes: { "最大张力": 112, "硬度": 13.4, "手感": 7.0 } },
                { id: "B_heavy_cast_blank", name: "B线重载远投竿胚", rarity: "传说", attributes: { "最大张力": 98, "硬度": 12.2, "手感": 8.1 } },
                { id: "C_exp_antenna_blank", name: "C线试验天线竿胚", rarity: "试验级", attributes: { "最大张力": 132, "硬度": 14.2, "手感": 9.4 } },
                { id: "C_exp_titan_blank", name: "C线试验泰坦竿胚", rarity: "试验级", attributes: { "最大张力": 152, "硬度": 15.8, "手感": 7.6 } }
            ],
            "芯骨": [
                { id: "A_std_quick_core", name: "A线标准快攻芯骨", rarity: "史诗", attributes: { "最大张力": 30, "硬度": 1.8, "手感": 1.4 } },
                { id: "A_std_solid_core", name: "A线标准实心芯骨", rarity: "史诗", attributes: { "最大张力": 38, "硬度": 2.4, "手感": 0.7 } },
                { id: "A_enh_suppress_core", name: "A线加强压制芯骨", rarity: "传说", attributes: { "最大张力": 56, "硬度": 3.1, "手感": 0.9 } },
                { id: "A_enh_flex_core", name: "A线加强柔控芯骨", rarity: "传说", attributes: { "最大张力": 44, "硬度": 2.2, "手感": 2.0 } },
                { id: "B_heavy_buffer_core", name: "B线重载缓冲芯", rarity: "传说", attributes: { "最大张力": 72, "硬度": 3.0, "手感": 2.6 } },
                { id: "B_heavy_spine_core", name: "B线重载脊芯", rarity: "传说", attributes: { "最大张力": 86, "硬度": 4.2, "手感": 1.3 } },
                { id: "C_exp_balance_core", name: "C线试验天衡芯", rarity: "试验级", attributes: { "最大张力": 102, "硬度": 4.4, "手感": 3.4 } },
                { id: "C_exp_void_core", name: "C线试验空渊芯", rarity: "试验级", attributes: { "最大张力": 122, "硬度": 5.6, "手感": 1.6 } }
            ],
            "导环组": [
                { id: "A_std_balance_guide", name: "A线标准平衡导环", rarity: "稀有", attributes: { "最大张力": 8, "硬度": -0.15, "手感": 1.8 } },
                { id: "A_enh_impact_guide", name: "A线加强抗冲导环", rarity: "史诗", attributes: { "最大张力": 18, "硬度": 0.35, "手感": 1.0 } },
                { id: "B_heavy_cast_guide", name: "B线重载远投导环", rarity: "史诗", attributes: { "最大张力": 26, "硬度": 0.25, "手感": 2.2 } },
                { id: "B_heavy_stable_guide", name: "B线重载稳线导环", rarity: "史诗", attributes: { "最大张力": 30, "硬度": 0.18, "手感": 2.6 } },
                { id: "C_exp_axis_guide", name: "C线试验轴线导环", rarity: "传说", attributes: { "最大张力": 38, "硬度": 0.45, "手感": 3.0 } },
                { id: "C_exp_vector_guide", name: "C线试验矢量导环", rarity: "传说", attributes: { "最大张力": 44, "硬度": 0.36, "手感": 3.3 } }
            ],
            "握柄": [
                { id: "A_std_control_grip", name: "A线标准控柄", rarity: "稀有", attributes: { "最大张力": 6, "硬度": -0.2, "手感": 2.3 } },
                { id: "A_enh_lock_grip", name: "A线加强锁柄", rarity: "史诗", attributes: { "最大张力": 18, "硬度": 0.4, "手感": 1.6 } },
                { id: "B_heavy_support_grip", name: "B线重载撑柄", rarity: "史诗", attributes: { "最大张力": 30, "硬度": 0.55, "手感": 2.4 } },
                { id: "B_heavy_balance_grip", name: "B线重载配重握柄", rarity: "史诗", attributes: { "最大张力": 26, "硬度": 0.35, "手感": 3.1 } },
                { id: "C_exp_anchor_grip", name: "C线试验锚柄", rarity: "传说", attributes: { "最大张力": 44, "硬度": 0.75, "手感": 3.2 } },
                { id: "C_exp_balance_grip", name: "C线试验平衡握柄", rarity: "传说", attributes: { "最大张力": 38, "硬度": 0.55, "手感": 4.1 } }
            ],
            "轮架": [
                { id: "A_std_baitcast_frame", name: "A线标准鼓轮轮架", rarity: "史诗", attributes: { "线容量": 1760, "最大摩擦力": 30, "最大收线速度": 1.15 } },
                { id: "A_std_spinning_frame", name: "A线标准纺车轮架", rarity: "史诗", attributes: { "线容量": 820, "最大摩擦力": 24, "最大收线速度": 3.4 } },
                { id: "A_enh_baitcast_frame", name: "A线加强鼓轮轮架", rarity: "传说", attributes: { "线容量": 2340, "最大摩擦力": 54, "最大收线速度": 1.55 } },
                { id: "A_enh_spinning_frame", name: "A线加强纺车轮架", rarity: "传说", attributes: { "线容量": 1120, "最大摩擦力": 42, "最大收线速度": 4.6 } },
                { id: "B_heavy_baitcast_frame", name: "B线重载鼓轮轮架", rarity: "传说", attributes: { "线容量": 3300, "最大摩擦力": 96, "最大收线速度": 2.05 } },
                { id: "B_heavy_spinning_frame", name: "B线重载纺车轮架", rarity: "传说", attributes: { "线容量": 1580, "最大摩擦力": 74, "最大收线速度": 6.0 } },
                { id: "C_exp_baitcast_frame", name: "C线试验鼓轮轮架", rarity: "试验级", attributes: { "线容量": 4620, "最大摩擦力": 154, "最大收线速度": 2.7 } },
                { id: "C_exp_spinning_frame", name: "C线试验纺车轮架", rarity: "试验级", attributes: { "线容量": 2220, "最大摩擦力": 118, "最大收线速度": 7.6 } }
            ],
            "齿列": [
                { id: "A_std_smooth_gear", name: "A线标准顺滑齿列", rarity: "稀有", attributes: { "最大收线速度": 0.25, "抛投系数": 5, "省力系数": 8 } },
                { id: "A_enh_speed_gear", name: "A线加强控速齿列", rarity: "史诗", attributes: { "最大收线速度": 0.35, "抛投系数": 7, "省力系数": 11 } },
                { id: "B_heavy_efficient_gear", name: "B线重载省力齿列", rarity: "史诗", attributes: { "最大收线速度": 0.36, "抛投系数": 8, "省力系数": 18 } },
                { id: "B_heavy_lock_gear", name: "B线重载锁合齿列", rarity: "史诗", attributes: { "最大收线速度": 0.48, "抛投系数": 10, "省力系数": 15 } },
                { id: "C_exp_rail_gear", name: "C线试验环轨齿列", rarity: "传说", attributes: { "最大收线速度": 0.68, "抛投系数": 13, "省力系数": 19 } },
                { id: "C_exp_silent_gear", name: "C线试验静音齿列", rarity: "传说", attributes: { "最大收线速度": 0.52, "抛投系数": 11, "省力系数": 23 } }
            ],
            "线杯": [
                { id: "A_std_long_spool", name: "A线标准长线杯", rarity: "稀有", attributes: { "线容量": 240, "最大摩擦力": 8, "最大收线速度": 0.35 } },
                { id: "A_enh_torque_spool", name: "A线加强扭矩线杯", rarity: "史诗", attributes: { "线容量": 520, "最大摩擦力": 22, "最大收线速度": 0.45 } },
                { id: "B_heavy_cast_spool", name: "B线重载远投线杯", rarity: "史诗", attributes: { "线容量": 760, "最大摩擦力": 34, "最大收线速度": 0.75 } },
                { id: "B_heavy_deep_spool", name: "B线重载深仓线杯", rarity: "史诗", attributes: { "线容量": 920, "最大摩擦力": 42, "最大收线速度": 0.6 } },
                { id: "C_exp_endless_spool", name: "C线试验无尽线杯", rarity: "传说", attributes: { "线容量": 1420, "最大摩擦力": 72, "最大收线速度": 0.8 } },
                { id: "C_exp_cast_spool", name: "C线试验远投线杯", rarity: "传说", attributes: { "线容量": 1180, "最大摩擦力": 62, "最大收线速度": 1.0 } }
            ],
            "制动组": [
                { id: "A_std_carbon_brake", name: "A线标准碳制动栈", rarity: "史诗", attributes: { "最大摩擦力": 38, "最大收线速度": -0.1, "省力系数": 3 } },
                { id: "A_enh_hydraulic_brake", name: "A线加强液压制动栈", rarity: "传说", attributes: { "最大摩擦力": 68, "最大收线速度": -0.08, "省力系数": 5 } },
                { id: "B_heavy_lock_brake", name: "B线重载抱死制动栈", rarity: "传说", attributes: { "最大摩擦力": 112, "最大收线速度": -0.06, "省力系数": 7 } },
                { id: "B_heavy_cool_brake", name: "B线重载散热制动栈", rarity: "传说", attributes: { "最大摩擦力": 104, "最大收线速度": 0.02, "省力系数": 9 } },
                { id: "C_exp_gravity_brake", name: "C线试验重力制动栈", rarity: "试验级", attributes: { "最大摩擦力": 168, "最大收线速度": -0.04, "省力系数": 9 } },
                { id: "C_exp_titanium_brake", name: "C线试验钛合制动栈", rarity: "试验级", attributes: { "最大摩擦力": 156, "最大收线速度": 0.04, "省力系数": 12 } }
            ],
            "材质母件": [
                { id: "A_std_steel_leader", name: "A线标准钢芯前导", rarity: "史诗", attributes: { "最大张力": 180, "线长": 2.4, "线径": 1.42 } },
                { id: "A_std_PE_mainline", name: "A线标准PE母线", rarity: "史诗", attributes: { "最大张力": 190, "线长": 1180, "线径": 1.24 } },
                { id: "A_enh_fluoro_leader", name: "A线加强隐氟前导", rarity: "传说", attributes: { "最大张力": 210, "线长": 4.4, "线径": 1.56 } },
                { id: "A_enh_PE_mainline", name: "A线加强PE母线", rarity: "传说", attributes: { "最大张力": 280, "线长": 1560, "线径": 1.58 } },
                { id: "B_heavy_steel_leader", name: "B线重载钢芯前导", rarity: "传说", attributes: { "最大张力": 360, "线长": 3.2, "线径": 2.05 } },
                { id: "B_heavy_PE_mainline", name: "B线重载PE母线", rarity: "传说", attributes: { "最大张力": 440, "线长": 2240, "线径": 2.08 } },
                { id: "C_exp_fluoro_leader", name: "C线试验隐氟前导", rarity: "试验级", attributes: { "最大张力": 470, "线长": 5.4, "线径": 2.32 } },
                { id: "C_exp_PE_mainline", name: "C线试验PE母线", rarity: "试验级", attributes: { "最大张力": 650, "线长": 3120, "线径": 2.72 } }
            ],
            "短涂层": [
                { id: "A_std_hydro_coat", name: "A线标准静水涂层", rarity: "稀有", attributes: { "最大张力": 8, "线长": 0.2, "线径": 0.01 } },
                { id: "A_std_lowflash_coat", name: "A线标准低闪涂层", rarity: "稀有", attributes: { "最大张力": 6, "线长": 80, "线径": 0.01 } },
                { id: "A_enh_antitbite_coat", name: "A线加强防咬涂层", rarity: "史诗", attributes: { "最大张力": 24, "线长": 0.35, "线径": 0.02 } },
                { id: "A_enh_wear_coat", name: "A线加强耐磨涂层", rarity: "史诗", attributes: { "最大张力": 18, "线长": 140, "线径": 0.02 } },
                { id: "B_heavy_hidden_coat", name: "B线重载隐护涂层", rarity: "史诗", attributes: { "最大张力": 52, "线长": 0.52, "线径": 0.03 } },
                { id: "B_heavy_matte_coat", name: "B线重载消光涂层", rarity: "史诗", attributes: { "最大张力": 44, "线长": 0.58, "线径": 0.025 } },
                { id: "B_heavy_shield_coat", name: "B线重载护盾涂层", rarity: "史诗", attributes: { "最大张力": 42, "线长": 260, "线径": 0.03 } },
                { id: "C_exp_traceless_coat", name: "C线试验无痕涂层", rarity: "传说", attributes: { "最大张力": 82, "线长": 0.78, "线径": 0.04 } },
                { id: "C_exp_shadow_coat", name: "C线试验影幕涂层", rarity: "传说", attributes: { "最大张力": 70, "线长": 0.9, "线径": 0.035 } },
                { id: "C_exp_hidden_coat", name: "C线试验隐幕涂层", rarity: "传说", attributes: { "最大张力": 68, "线长": 420, "线径": 0.04 } }
            ],
            "缓冲层": [
                { id: "A_std_buffer", name: "A线标准缓冲段", rarity: "稀有", attributes: { "最大张力": 12, "线长": 0.35, "线径": 0.02 } },
                { id: "A_enh_iron_buffer", name: "A线加强铁幕缓冲段", rarity: "史诗", attributes: { "最大张力": 34, "线长": 0.55, "线径": 0.04 } },
                { id: "B_heavy_elastic_buffer", name: "B线重载弹性缓冲段", rarity: "史诗", attributes: { "最大张力": 60, "线长": 1.0, "线径": 0.05 } },
                { id: "B_heavy_pulse_buffer", name: "B线重载脉冲缓冲段", rarity: "史诗", attributes: { "最大张力": 68, "线长": 0.82, "线径": 0.06 } },
                { id: "C_exp_gravity_buffer", name: "C线试验重力缓冲段", rarity: "传说", attributes: { "最大张力": 96, "线长": 1.32, "线径": 0.07 } },
                { id: "C_exp_inertia_buffer", name: "C线试验惯性缓冲段", rarity: "传说", attributes: { "最大张力": 108, "线长": 1.1, "线径": 0.08 } }
            ],
            "编织层": [
                { id: "A_std_cast_braid", name: "A线标准远投编织层", rarity: "稀有", attributes: { "最大张力": 12, "线长": 180, "线径": 0.02 } },
                { id: "A_enh_warpspine_braid", name: "A线加强战脊编织层", rarity: "史诗", attributes: { "最大张力": 32, "线长": 260, "线径": 0.05 } },
                { id: "B_heavy_load_braid", name: "B线重载承载编织层", rarity: "史诗", attributes: { "最大张力": 62, "线长": 420, "线径": 0.08 } },
                { id: "B_heavy_lowres_braid", name: "B线重载低阻编织层", rarity: "史诗", attributes: { "最大张力": 54, "线长": 520, "线径": 0.065 } },
                { id: "C_exp_phase_braid", name: "C线试验相位编织层", rarity: "传说", attributes: { "最大张力": 84, "线长": 760, "线径": 0.095 } },
                { id: "C_exp_singularity_braid", name: "C线试验奇点编织层", rarity: "传说", attributes: { "最大张力": 96, "线长": 640, "线径": 0.12 } }
            ],
            "钩型母件": [
                { id: "A_std_single_hook_master", name: "A线标准竞技单钩坯", rarity: "史诗", attributes: { "钩型": "单钩", "号数": "12/0", "最大张力": 300 } },
                { id: "A_enh_treble_hook_master", name: "A线加强爆击三本坯", rarity: "传说", attributes: { "钩型": "三本钩", "号数": "15/0", "最大张力": 420 } },
                { id: "B_heavy_ocean_hook_master", name: "B线重载远洋单钩坯", rarity: "传说", attributes: { "钩型": "单钩", "号数": "23/0", "最大张力": 720 } },
                { id: "C_exp_deep_gun_hook_master", name: "C线试验深海枪钩坯", rarity: "试验级", attributes: { "钩型": "单钩", "号数": "30/0", "最大张力": 960 } }
            ],
            "钩身线材": [
                { id: "A_std_fine_bone_hook_body", name: "A线标准细骨钩身", rarity: "稀有", attributes: { "最大张力": 36, "挂底系数": -1, "识别度": -3 } },
                { id: "A_enh_barb_hook_body", name: "A线加强倒刺钩身", rarity: "史诗", attributes: { "最大张力": 82, "挂底系数": 3, "识别度": 2 } },
                { id: "B_heavy_spine_hook_body", name: "B线重载脊骨钩身", rarity: "史诗", attributes: { "最大张力": 140, "挂底系数": 4, "识别度": 2 } },
                { id: "C_exp_titan_hook_body", name: "C线试验泰坦钩身", rarity: "传说", attributes: { "最大张力": 220, "挂底系数": 5, "识别度": 3 } }
            ],
            "拟饵主体": [
                { id: "A_std_swim_lure_body", name: "A线标准游鱼主体", rarity: "史诗", attributes: { "拟饵类型": "米诺", "颜色": "blue_black", "号数": "61.5号" } },
                { id: "A_enh_deep_jig_lure_body", name: "A线加强深投铁板主体", rarity: "传说", attributes: { "拟饵类型": "铅头钩", "颜色": "abyss_silver", "号数": "72号" } },
                { id: "B_heavy_soft_lure_body", name: "B线重载软饵主体", rarity: "传说", attributes: { "拟饵类型": "软饵", "颜色": "abyss_glow", "号数": "94.5号" } },
                { id: "C_exp_pencil_lure_body", name: "C线试验巡天铅笔主体", rarity: "试验级", attributes: { "拟饵类型": "水面系", "颜色": "bone_blue", "号数": "118.5号" } }
            ],
            "配重组": [
                { id: "A_std_keel_weight", name: "A线标准龙骨配重", rarity: "稀有", attributes: { "号数": "1.6号", "重量": 28, "扰流": 5 } },
                { id: "A_enh_deep_weight", name: "A线加强深沉配重", rarity: "史诗", attributes: { "号数": "2.1号", "重量": 54, "扰流": 8 } },
                { id: "B_heavy_torque_weight", name: "B线重载扭矩配重", rarity: "史诗", attributes: { "号数": "2.8号", "重量": 88, "扰流": 10 } },
                { id: "C_exp_rail_weight", name: "C线试验轨道配重", rarity: "传说", attributes: { "号数": "3.4号", "重量": 126, "扰流": 12 } }
            ]
        };

        // ==================== 槽位配置 ====================
        const EQUIPMENT_SLOTS = {
            "底钓竿": [{ name: "竿胚", required: true, type: "不可逆固化件" }, { name: "芯骨", required: false, type: "不可逆固化件" }, { name: "导环组", required: true, type: "可热插拔模块件" }, { name: "握柄", required: true, type: "可热插拔模块件" }],
            "赛竿": [{ name: "竿胚", required: true, type: "不可逆固化件" }, { name: "芯骨", required: false, type: "不可逆固化件" }, { name: "导环组", required: true, type: "可热插拔模块件" }, { name: "握柄", required: true, type: "可热插拔模块件" }],
            "路亚竿": [{ name: "竿胚", required: true, type: "不可逆固化件" }, { name: "芯骨", required: false, type: "不可逆固化件" }, { name: "导环组", required: true, type: "可热插拔模块件" }, { name: "握柄", required: true, type: "可热插拔模块件" }],
            "纺车轮": [{ name: "轮架", required: true, type: "不可逆固化件" }, { name: "制动组", required: true, type: "可热插拔模块件" }, { name: "线杯", required: true, type: "可热插拔模块件" }, { name: "齿列", required: true, type: "可热插拔模块件" }],
            "鼓轮": [{ name: "轮架", required: true, type: "不可逆固化件" }, { name: "制动组", required: true, type: "可热插拔模块件" }, { name: "线杯", required: true, type: "可热插拔模块件" }, { name: "齿列", required: true, type: "可热插拔模块件" }],
            "主线": [{ name: "材质母件", required: true, type: "不可逆固化件" }, { name: "短涂层", required: false, type: "涂层" }, { name: "编织层", required: false, type: "编织层" }],
            "引线": [{ name: "材质母件", required: true, type: "不可逆固化件" }, { name: "缓冲层", required: false, type: "缓冲层" }, { name: "短涂层", required: false, type: "涂层" }],
            "鱼钩": [{ name: "钩型母件", required: true, type: "不可逆固化件" }, { name: "钩身线材", required: false, type: "可热插拔模块件" }],
            "拟饵": [{ name: "拟饵主体", required: true, type: "不可逆固化件" }, { name: "配重组", required: false, type: "可热插拔模块件" }]
        };

        // ==================== 区间配置 ====================
        const EQUIPMENT_RANGE = {
            "底钓竿": [-20, 20], "赛竿": [-10, -40], "路亚竿": [-20, 20],
            "纺车轮": [-28, 8], "鼓轮": [-5, 42],
            "主线": [-20, 20], "引线": [-20, 20],
            "鱼钩": [-15, 15], "拟饵": [-20, 20]
        };

        // ==================== 稀有度颜色 ====================
        const RARITY_COLORS = { "稀有": "#4a9eff", "史诗": "#a335ee", "传说": "#ff8000", "试验级": "#ff4040" };

        let currentEquipment = null, currentAssembly = {};

        // ==================== 面板管理 ====================
        function getOrCreatePanel() {
            let panel = document.getElementById('asm-sim-panel');
            if (panel) return panel;
            const grid = document.querySelector('.workshop-assembly-slot-grid');
            if (!grid) return null;
            panel = document.createElement('div');
            panel.id = 'asm-sim-panel';
            panel.className = 'card mt-sm';
            panel.innerHTML = `
                <strong>装配模拟器</strong>
                <div class="text-xs text-muted mt-xs">选择零件查看理论属性区间</div>
                <div class="workshop-assembly-slot-grid mt-sm" id="asm-sim-slots">
                    <div class="text-sm text-muted" style="grid-column:1/-1;">请先选择装备类型</div>
                </div>
                <div class="card mt-sm" id="asm-sim-preview">
                    <strong>区间预览</strong>
                    <div class="text-sm text-muted mt-sm">选满所有必选槽位后显示区间预览。</div>
                </div>
                <div class="flex items-center justify-between gap-sm mt-sm">
                    <span class="text-xs text-muted">数据仅供参考，实际效果请以游戏正式版为准。</span>
                    <button class="btn btn-ghost btn-sm" id="asm-sim-reset-btn">重置全部</button>
                </div>`;
            grid.closest('.card').parentNode.insertBefore(panel, grid.closest('.card').nextSibling);
            panel.querySelector('#asm-sim-reset-btn').addEventListener('click', () => {
                Object.keys(currentAssembly).forEach(k => currentAssembly[k] = null);
                renderSlots(); updatePreview();
            });
            return panel;
        }

        // ==================== 状态与渲染 ====================
        function getEquipmentType() {
            const tab = document.querySelector('.workshop-assembly-slot-grid')?.closest('.card')?.querySelector('.tab-active');
            return tab ? tab.textContent.trim() : null;
        }
        function getSlots() { return currentEquipment ? (EQUIPMENT_SLOTS[currentEquipment] || []) : []; }
        function getRange() { return currentEquipment ? (EQUIPMENT_RANGE[currentEquipment] || [-20, 20]) : [-20, 20]; }

        function initState() {
            currentEquipment = getEquipmentType();
            currentAssembly = {};
            getSlots().forEach(s => currentAssembly[s.name] = null);
        }

        function formatAttrShort(attrs) {
            if (!attrs) return '';
            const entries = Object.entries(attrs).filter(([k]) => !k.includes('号数') && !k.includes('号'));
            if (entries.length === 0) return '';
            return entries.length <= 3 ? entries.map(([k, v]) => `${k}: ${v}`).join(' · ') : entries.slice(0, 2).map(([k, v]) => `${k}: ${v}`).join(' · ') + ' ...';
        }

        function renderSlots() {
            const grid = document.getElementById('asm-sim-slots');
            if (!grid) return;
            const slots = getSlots();
            if (!slots.length) { grid.innerHTML = '<div class="text-sm text-muted" style="grid-column:1/-1;">请先选择装备类型</div>'; return; }
            grid.innerHTML = slots.map(s => {
                const p = currentAssembly[s.name], empty = !p, has = PART_LIBRARY[s.name]?.length > 0;
                return `<button class="loadout-slot workshop-assembly-slot-card ${empty ? 'workshop-assembly-slot-card--empty' : ''} ${!has ? 'workshop-assembly-slot-card--disabled' : ''}" data-slot="${s.name}" ${!has ? 'disabled' : ''}>
                    <div class="loadout-slot-top"><div class="loadout-slot-title"><span class="loadout-slot-label">${s.name}</span></div><span class="loadout-slot-action">${empty ? '选择' : '更换'}</span></div>
                    <span class="loadout-slot-empty" style="color:${p ? RARITY_COLORS[p.rarity] || '' : ''}">${p ? p.name : '未选择'}</span></button>`;
            }).join('');
            grid.querySelectorAll('.workshop-assembly-slot-card:not([disabled])').forEach(btn => {
                btn.addEventListener('click', () => showModal(btn.dataset.slot));
            });
        }

        function updatePreview() {
            const card = document.getElementById('asm-sim-preview');
            if (!card) return;
            const slots = getSlots(), [lo, hi] = getRange();
            let ok = true; const totals = {};
            slots.forEach(s => {
                const p = currentAssembly[s.name];
                if (s.required && !p) ok = false;
                if (p?.attributes) Object.entries(p.attributes).forEach(([k, v]) => totals[k] = (totals[k] || 0) + v);
            });
            if (!slots.length) card.innerHTML = '<strong>区间预览</strong><div class="text-sm text-muted mt-sm">请先选择装备类型。</div>';
            else if (!ok || !Object.keys(totals).length) card.innerHTML = '<strong>区间预览</strong><div class="text-sm text-muted mt-sm">选满所有必选槽位后显示区间预览。</div>';
            else card.innerHTML = `<strong>区间预览</strong><div class="flex flex-col gap-xs mt-sm">${Object.entries(totals).map(([k, v]) => `<div class="flex items-center justify-between text-sm"><span>${k}</span><span class="text-muted">${(v * (1 + lo / 100)).toFixed(2)} - ${(v * (1 + hi / 100)).toFixed(2)}</span></div>`).join('')}</div>`;
        }

        // ==================== 弹窗 ====================
        function showModal(slotName) {
            closeModal();
            const parts = PART_LIBRARY[slotName] || [];
            if (!parts.length) return;
            const sel = currentAssembly[slotName];
            const overlay = document.createElement('div');
            overlay.id = 'asm-sim-overlay';
            Object.assign(overlay.style, { position: 'fixed', inset: 0, background: 'rgba(0,0,0,.55)', zIndex: 99998, display: 'flex', alignItems: 'center', justifyContent: 'center' });
            const modal = document.createElement('div');
            modal.id = 'asm-sim-modal';
            modal.className = 'card';
            Object.assign(modal.style, { position: 'relative', zIndex: 99999, maxWidth: '520px', width: '92%', maxHeight: '78vh', overflowY: 'auto', padding: '16px' });
            modal.innerHTML = `
                <div class="flex items-center justify-between mb-sm" style="position:sticky;top:0;background:inherit;z-index:1;"><strong>选择 ${slotName}</strong><button class="btn btn-sm" id="asm-sim-close-btn">✕ 关闭</button></div>
                ${sel ? `<div class="alert alert-info mb-sm text-sm">当前已选: <span style="color:${RARITY_COLORS[sel.rarity] || '#fff'};">${sel.name}</span></div><button class="btn btn-sm btn-ghost mb-sm" id="asm-sim-clear-btn">清除选择</button>` : ''}
                <div class="flex flex-col gap-xs">${parts.map(p => {
                    const isSel = sel?.id === p.id;
                    return `<div class="asm-part-item flex items-center justify-between p-sm" data-part-id="${p.id}" style="cursor:pointer;border-radius:4px;background:${isSel ? 'var(--color-base-300,#333)' : 'transparent'};transition:background .15s;">
                        <div><span style="color:${RARITY_COLORS[p.rarity] || '#ccc'};font-weight:600;">${p.name}</span><span class="text-xs text-muted ml-xs">${p.rarity}</span></div>
                        <span class="text-xs text-muted">${formatAttrShort(p.attributes)}</span></div>`;
                }).join('')}</div>`;
            overlay.appendChild(modal);
            document.body.appendChild(overlay);
            document.getElementById('asm-sim-close-btn').addEventListener('click', closeModal);
            overlay.addEventListener('click', e => { if (e.target === overlay) closeModal(); });
            const clearBtn = document.getElementById('asm-sim-clear-btn');
            if (clearBtn) clearBtn.addEventListener('click', () => { currentAssembly[slotName] = null; renderSlots(); updatePreview(); closeModal(); });
            modal.querySelectorAll('.asm-part-item').forEach(item => {
                item.addEventListener('click', () => {
                    const p = parts.find(x => x.id === item.dataset.partId);
                    if (p) { currentAssembly[slotName] = p; renderSlots(); updatePreview(); closeModal(); }
                });
                item.addEventListener('mouseenter', function() { this.style.background = 'var(--color-base-300,#333)'; });
                item.addEventListener('mouseleave', function() { this.style.background = sel?.id === item.dataset.partId ? 'var(--color-base-300,#333)' : 'transparent'; });
            });
        }

        function closeModal() { const o = document.getElementById('asm-sim-overlay'); if (o) o.remove(); }

        // ==================== 入口 ====================
        function tryInit() {
            if (!document.querySelector('.workshop-assembly-slot-grid') || document.getElementById('asm-sim-panel')) return;
            getOrCreatePanel(); initState(); renderSlots(); updatePreview();
            const tabs = document.querySelector('.workshop-assembly-slot-grid')?.closest('.card')?.querySelector('.scroll-row');
            if (tabs) tabs.addEventListener('click', e => {
                if (e.target.closest('.tab')) setTimeout(() => { initState(); renderSlots(); updatePreview(); }, 150);
            });
        }

        function main() {
            tryInit();
            new MutationObserver(tryInit).observe(document.body, { childList: true, subtree: true });
            document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
        }

        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', main);
        else main();
    })();
}
// 功能：钩子张力标注 v2 -
// 注册名：initHookStrength
// ============================================================
function initHookStrength() {
    (function() {
        'use strict';

        // 直接用全局的 HOOK_STRENGTH_DATA，不再自己声明
        let HOOK_NAME_TO_STRENGTH = {};
        let HOOK_MODEL_TO_STRENGTH = {};

        function initCache() {
            const data = window.HOOK_STRENGTH_DATA || [];
            for (let i = 0; i < data.length; i++) {
                const item = data[i];
                const cleanName = hookNormalizeName(item.name);
                HOOK_NAME_TO_STRENGTH[cleanName] = item.strength;

                const modelMatch = item.name.match(/([A-Z]{1,3}[-\s][A-Z]?\d{1,3}[A-Z]?)/);
                if (modelMatch) {
                    HOOK_MODEL_TO_STRENGTH[modelMatch[1]] = item.strength;
                }
            }
        }

        function hookNormalizeName(rawName) {
            return rawName.trim().replace(/\s+/g, ' ').replace(/·/g, '·');
        }

        function hookFindStrength(pageHookName) {
            if (!pageHookName) return null;
            const pageClean = hookNormalizeName(pageHookName);
            if (HOOK_NAME_TO_STRENGTH[pageClean]) {
                return HOOK_NAME_TO_STRENGTH[pageClean];
            }
            const modelMatch = pageHookName.match(/([A-Z]{1,3}[-\s][A-Z]?\d{1,3}[A-Z]?)/);
            if (modelMatch && HOOK_MODEL_TO_STRENGTH[modelMatch[1]]) {
                return HOOK_MODEL_TO_STRENGTH[modelMatch[1]];
            }
            return null;
        }

        function createStrengthTag(strength) {
            const span = document.createElement('span');
            span.className = 'hook-strength-result';
            span.textContent = `最大张力${strength}`;
            span.style.cssText = 'color:#64748B;font-weight:bold;margin-left:5px;';
            return span;
        }

        function enhanceHookCard(card) {
            if (card.querySelector('.hook-strength-result')) return;
            const nameElement = card.querySelector('.item-name--multiline');
            if (!nameElement) return;
            const hookName = nameElement.textContent.trim();
            if (!hookName) return;
            const strength = hookFindStrength(hookName);
            if (strength === null) return;
            const metaContainer = card.querySelector('.shop-card-meta');
            if (!metaContainer) return;
            metaContainer.appendChild(createStrengthTag(strength));
        }

        function enhanceEquipmentHeader(header) {
            if (header.querySelector('.hook-strength-result')) return;
            const nameElement = header.querySelector('.equipment-item-name');
            if (!nameElement) return;
            const hookName = nameElement.textContent.trim();
            if (!hookName) return;
            const strength = hookFindStrength(hookName);
            if (strength === null) return;
            const metaContainer = header.querySelector('.equipment-item-header-meta');
            if (!metaContainer) return;
            metaContainer.appendChild(createStrengthTag(strength));
        }

        function enhanceLoadoutSlot(slot) {
            if (slot.querySelector('.hook-strength-result')) return;
            const label = slot.querySelector('.loadout-slot-label');
            if (!label || label.textContent.trim() !== '鱼钩') return;

            const nameElement = slot.querySelector('.loadout-slot-name');
            if (!nameElement) return;

            const hookName = nameElement.textContent.trim();
            const strength = hookFindStrength(hookName);
            if (strength === null) return;

            const metaContainer = slot.querySelector('.loadout-slot-meta');
            if (metaContainer) {
                metaContainer.appendChild(createStrengthTag(strength));
            }
        }

        function hookEnhanceAll() {
            requestAnimationFrame(() => {
                const shopCards = document.querySelectorAll('.square-item-card-content');
                for (let i = 0; i < shopCards.length; i++) {
                    enhanceHookCard(shopCards[i]);
                }
                const headers = document.querySelectorAll('.equipment-item-header');
                for (let i = 0; i < headers.length; i++) {
                    enhanceEquipmentHeader(headers[i]);
                }
                const slots = document.querySelectorAll('.loadout-slot');
                for (let i = 0; i < slots.length; i++) {
                    enhanceLoadoutSlot(slots[i]);
                }
            });
        }

        function init() {
            // 等待数据就绪后再初始化
            window.__onHookStrengthReady(function() {
                initCache();
                hookEnhanceAll();
                const observer = new MutationObserver(() => {
                    if (window.__hookStrengthDebounce) {
                        clearTimeout(window.__hookStrengthDebounce);
                    }
                    window.__hookStrengthDebounce = setTimeout(hookEnhanceAll, 50);
                });
                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });
            });
        }
        init();
    })();
}
//鱼获卡片分级背景标记
function initFishCardGradeColor() {
    (function() {
        'use strict';
        const FISH_OBSERVER_OPTIONS = { childList: true, subtree: true };
        const GRADE_STYLES = {
            '不达标': { bg: '#CDD3DC', border: '#8390A0' },
            '达标':   { bg: '#C2EFD5', border: '#6FB58A' },
            '稀有':   { bg: '#C5DAFC', border: '#7A9EE0' },
            '罕见':   { bg: '#F7E2B5', border: '#D49E40' },
            '传说':   { bg: '#F5CDCE', border: '#D47478' }
        };
        const LOW_RATING_STYLE = { bg: '#F4F0A2', border: '#C4B530' };
        const LOW_RATING_THRESHOLD = 2.0;

        function getFishCardGradeInfo(card) {
            const metaLine = card.querySelector('.square-card-meta-line');
            if (!metaLine) return null;

            const metaSpans = metaLine.querySelectorAll('.inline-meta');
            if (metaSpans.length < 2) return null;

            const gradeText = metaSpans[0].textContent.trim();
            const percentText = metaSpans[1].textContent.trim().replace('%', '');
            const percent = parseFloat(percentText);
            if (isNaN(percent)) return null;

            return { grade: gradeText, percent: percent };
        }

        function applyCardStyle(card) {
            if (card.dataset.fishGradeStyled) return;

            const info = getFishCardGradeInfo(card);
            if (!info) return;

            let style;
            if (info.percent < LOW_RATING_THRESHOLD) {
                style = LOW_RATING_STYLE;
            } else {
                style = GRADE_STYLES[info.grade];
                if (!style) return;
            }

            card.style.backgroundColor = style.bg;
            card.style.border = '2px solid ' + style.border;
            card.dataset.fishGradeStyled = 'true';
        }

        function processAllCards() {
            document.querySelectorAll('.square-item-card').forEach(card => {
                if (!card.querySelector('.square-card-meta-line')) return;
                applyCardStyle(card);
            });
        }

        setTimeout(processAllCards, 500);
        const fishObserver = new MutationObserver(() => processAllCards());
        fishObserver.observe(document.body, FISH_OBSERVER_OPTIONS);
        console.log('[鱼获卡片分级背景标记] 已启动（浅色背景+深色边框）');
    })();
}
// 14. 鱼获卡片分级动态辉光
function initFishCardGlow() {
    (function() {
        'use strict';
        const FISH_OBSERVER_OPTIONS = { childList: true, subtree: true };
        const LOW_RATING_THRESHOLD = 2.0;

        // 辉光颜色（取自边框色并提高亮度）
        const GLOW_COLORS = {
            '不达标': '#A0B0C0',
            '达标':   '#90D0A0',
            '稀有':   '#A0C0F0',
            '罕见':   '#F0C880',
            '传说':   '#F08090'
        };
        const LOW_RATING_GLOW_COLOR = '#E0D030';

        // 呼吸周期（秒）：传说最快 → 不达标最慢
        const GLOW_SPEEDS = {
            '不达标': 2.5,
            '达标':   2.0,
            '稀有':   1.6,
            '罕见':   1.2,
            '传说':   0.8,
            'lowRating': 2.2   // <2% 的呼吸速度（略快于达标）
        };

        // 随机偏移量，防止所有卡片同步呼吸
        function randDelay(max = 2.0) {
            return (Math.random() * max).toFixed(2);
        }

        // 动态插入 @keyframes
        function injectKeyframes() {
            if (document.getElementById('fish-glow-keyframes')) return;
            const style = document.createElement('style');
            style.id = 'fish-glow-keyframes';
            let css = '';
            for (const [grade, color] of Object.entries(GLOW_COLORS)) {
                css += `
                @keyframes fishGlow-${grade.replace(/\s/g, '_')} {
                    0%, 100% { box-shadow: 0 0 6px 0px ${color}40; }
                    50%      { box-shadow: 0 0 12px 2px ${color}90; }
                }`;
            }
            // 低评分动画
            css += `
            @keyframes fishGlow-lowRating {
                0%, 100% { box-shadow: 0 0 6px 0px ${LOW_RATING_GLOW_COLOR}40; }
                50%      { box-shadow: 0 0 12px 2px ${LOW_RATING_GLOW_COLOR}90; }
            }`;
            style.textContent = css;
            document.head.appendChild(style);
        }

        // 提取等级信息（复用已有逻辑）
        function getFishCardGradeInfo(card) {
            const metaLine = card.querySelector('.square-card-meta-line');
            if (!metaLine) return null;
            const metaSpans = metaLine.querySelectorAll('.inline-meta');
            if (metaSpans.length < 2) return null;
            const gradeText = metaSpans[0].textContent.trim();
            const percentText = metaSpans[1].textContent.trim().replace('%', '');
            const percent = parseFloat(percentText);
            if (isNaN(percent)) return null;
            return { grade: gradeText, percent: percent };
        }

        // 为卡片应用辉光类
        function applyGlow(card) {
            if (card.dataset.fishGlowApplied) return;
            const info = getFishCardGradeInfo(card);
            if (!info) return;

            let animName, duration;
            if (info.percent < LOW_RATING_THRESHOLD) {
                animName = 'fishGlow-lowRating';
                duration = GLOW_SPEEDS.lowRating;
            } else {
                const speed = GLOW_SPEEDS[info.grade];
                if (!speed) return;
                animName = `fishGlow-${info.grade.replace(/\s/g, '_')}`;
                duration = speed;
            }

            card.style.animation = `${animName} ${duration}s ease-in-out ${randDelay()}s infinite`;
            card.dataset.fishGlowApplied = 'true';
        }

        // 批量处理
        function processAllCards() {
            document.querySelectorAll('.square-item-card').forEach(card => {
                if (!card.querySelector('.square-card-meta-line')) return;
                applyGlow(card);
            });
        }

        // 启动
        injectKeyframes();
        setTimeout(processAllCards, 600);
        const fishObserver = new MutationObserver(() => processAllCards());
        fishObserver.observe(document.body, FISH_OBSERVER_OPTIONS);
        console.log('[鱼获卡片动态辉光] 已启动（传说最快）');
    })();
}
// 15. 高难挑战鱼种资料自动展示
function initChallengeFishInfo() {
    (function() {
        'use strict';
        const CHALLENGE_OBSERVER_OPTIONS = { childList: true, subtree: true };

        // 优先使用全局 FISH_DATABASE，若未定义则给出警告并使用空数组
        const FISH_DB = (typeof FISH_DATABASE !== 'undefined') ? FISH_DATABASE : (() => {
            console.warn('[高难挑战鱼种资料] 未找到全局 FISH_DATABASE，无法展示信息');
            return [];
        })();

        // 名称标准化
        function normalizeName(str) {
            return str.trim().replace(/\s+/g, '');
        }

        // 根据鱼名查找数据库条目（兼容您提供的 JSON 结构）
        function findFishData(fishName) {
            const cleaned = normalizeName(fishName);
            return FISH_DB.find(fish => {
                const dbName = fish.名称 || fish.name || ''; // 兼容多种键名
                return normalizeName(dbName) === cleaned;
            }) || null;
        }

        // 提取字段辅助函数
        function getDetail(fishData, key) {
            if (fishData.详情 && fishData.详情[key] !== undefined) {
                return fishData.详情[key];
            }
            if (fishData[key] !== undefined) {
                return fishData[key];
            }
            return '—';
        }

        // 构建信息面板
        function buildInfoPanel(fishData) {
            const area = getDetail(fishData, '分布区域');
            const layer = getDetail(fishData, '水层');
            const bait = getDetail(fishData, '偏好饵料');
            const lure = getDetail(fishData, '偏好拟饵');
            const minWeight = getDetail(fishData, '最小重量');
            const minSize = getDetail(fishData, '最小尺寸');

            const panel = document.createElement('div');
            panel.className = 'challenge-fish-info-panel';
            panel.style.cssText = `
                margin-top: 0.5rem;
                padding: 0.5rem 0.75rem;
                background: rgba(255,255,255,0.06);
                border-radius: 6px;
                font-size: 0.85rem;
                line-height: 1.6;
                color: var(--color-text-secondary, #94a3b8);
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 0.2rem 1rem;
            `;
            panel.innerHTML = `
                <span><strong>分布区域</strong> ${area}</span>
                <span><strong>水层</strong> ${layer}</span>
                <span><strong>偏好饵料</strong> ${bait}</span>
                <span><strong>偏好拟饵</strong> ${lure}</span>
                <span><strong>最小重量</strong> ${minWeight}</span>
                <span><strong>最小尺寸</strong> ${minSize}</span>
            `;
            return panel;
        }

        // 处理单个挑战卡片
        function enhanceChallengeCard(card) {
            if (card.dataset.challengeInfoEnhanced) return;

            const nameEl = card.querySelector('.license-name');
            if (!nameEl) return;
            const fishName = nameEl.textContent.trim();
            if (!fishName) return;

            const fishData = findFishData(fishName);
            if (!fishData) return; // 数据库中没有该鱼种则不处理

            const progressEl = card.querySelector('.task-progress');
            if (!progressEl) return;
            progressEl.insertAdjacentElement('afterend', buildInfoPanel(fishData));
            card.dataset.challengeInfoEnhanced = 'true';
        }

        // 批量处理
        function processAllChallenges() {
            document.querySelectorAll('.license-card').forEach(card => {
                enhanceChallengeCard(card);
            });
        }

        // 启动
        setTimeout(processAllChallenges, 500);
        const challengeObserver = new MutationObserver(() => processAllChallenges());
        challengeObserver.observe(document.body, CHALLENGE_OBSERVER_OPTIONS);
        console.log('[高难挑战鱼种资料] 已启动（数据库条目：' + FISH_DB.length + '）');
    })();
}
// 16. 钓鱼实时状态波动图
function initRealtimeChart() {
    (function() {
        'use strict';

        const UPDATE_INTERVAL = 500;
        const MAX_DATA_POINTS = 500;
        const CHART_HEIGHT = 160;
        const LINE_COLORS = {
            lineOut: '#D1D1D1',
            playerStamina: '#2F82CC',
            fishStamina: '#ef4444'
        };
        const LINE_LABELS = {
            tension: '张力',
            lineOut: '出线',
            playerStamina: '玩家体力',
            fishStamina: '鱼体力'
        };
        const GRID_COLOR = '#334155';
        const TEXT_COLOR = '#94a3b8';

        let canvas, ctx;
        let dataPoints = [];                  // 始终保留第一个点为 R1
        let lastRecordedRound = null;
        let chartInserted = false;
        let chartInterval = null;

        // 获取包含“实时状态”标题的卡片
        function getStatusCard() {
            const cards = document.querySelectorAll('.fishing-compact-card');
            for (const card of cards) {
                const header = card.querySelector('.flex.items-center.gap-sm span');
                if (header && header.textContent.trim() === '实时状态') {
                    return card;
                }
            }
            return null;
        }

        // 获取当前轮次
        function getCurrentRound() {
            const statusCard = getStatusCard();
            if (!statusCard) return null;
            const roundEl = statusCard.querySelector('.text-xs.text-muted');
            if (!roundEl) return null;
            const match = roundEl.textContent.match(/第\s*(\d+)\s*轮/);
            return match ? match[1] : null;
        }

        // 读取四个指标百分比
        function readPercentages() {
            const statusCard = getStatusCard();
            if (!statusCard) return null;

            const metricCards = statusCard.querySelectorAll('.fishing-metric-card');
            const values = { tension: undefined, lineOut: undefined, playerStamina: undefined, fishStamina: undefined };

            for (const card of metricCards) {
                const labelEl = card.querySelector('.fishing-metric-label');
                if (!labelEl) continue;
                const text = labelEl.textContent.trim();

                if (text.includes('张力') && values.tension === undefined) {
                    values.tension = extractPercent(card);
                } else if (text.includes('出线') && values.lineOut === undefined) {
                    values.lineOut = extractPercent(card);
                } else if (text.includes('玩家体力') && values.playerStamina === undefined) {
                    values.playerStamina = extractPercent(card);
                } else if (text.includes('鱼体力') && values.fishStamina === undefined) {
                    values.fishStamina = extractPercent(card);
                }
            }

            if (Object.values(values).some(v => v === undefined)) return null;
            return values;
        }

        function extractPercent(card) {
            const fill = card.querySelector('.progress-bar-fill');
            if (!fill || !fill.style.width) return undefined;
            const w = parseFloat(fill.style.width);
            if (isNaN(w)) return undefined;
            return w / 100;
        }

        // 动态获取张力进度条颜色
        function getDynamicTensionColor() {
            const statusCard = getStatusCard();
            if (!statusCard) return '#22c55e';
            const cards = statusCard.querySelectorAll('.fishing-metric-card');
            for (const card of cards) {
                const label = card.querySelector('.fishing-metric-label');
                if (label && label.textContent.trim().includes('张力')) {
                    const fill = card.querySelector('.progress-bar-fill');
                    if (fill) {
                        const style = window.getComputedStyle(fill);
                        return style.backgroundColor || '#22c55e';
                    }
                }
            }
            return '#22c55e';
        }

        // 插入 Canvas
        function insertChart() {
            if (chartInserted) return;
            const targetCard = getStatusCard();
            if (!targetCard) return;

            const chartWrapper = document.createElement('div');
            chartWrapper.className = 'realtime-chart-wrapper';
            chartWrapper.style.marginBottom = '0.5rem';

            canvas = document.createElement('canvas');
            canvas.width = targetCard.clientWidth || 600;
            canvas.height = CHART_HEIGHT;
            canvas.style.width = '100%';
            canvas.style.height = CHART_HEIGHT + 'px';
            canvas.style.background = 'rgba(15, 23, 42, 0.8)';
            canvas.style.borderRadius = '8px';

            chartWrapper.appendChild(canvas);
            targetCard.parentNode.insertBefore(chartWrapper, targetCard);

            ctx = canvas.getContext('2d');
            chartInserted = true;

            window.addEventListener('resize', () => {
                if (canvas && targetCard) {
                    canvas.width = targetCard.clientWidth || 600;
                    drawChart();
                }
            });
        }

        // 绘制图表
        function drawChart() {
            if (!ctx || !canvas) return;
            const w = canvas.width;
            const h = canvas.height;
            ctx.clearRect(0, 0, w, h);
            ctx.fillStyle = '#0f172a';
            ctx.fillRect(0, 0, w, h);

            if (dataPoints.length === 0) {
                ctx.fillStyle = TEXT_COLOR;
                ctx.font = '12px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText('等待钓鱼数据…', w / 2, h / 2);
                return;
            }

            const padding = { top: 20, bottom: 30, left: 40, right: 20 };
            const chartW = w - padding.left - padding.right;
            const chartH = h - padding.top - padding.bottom;

            // 网格与Y轴
            ctx.strokeStyle = GRID_COLOR;
            ctx.lineWidth = 0.5;
            ctx.fillStyle = TEXT_COLOR;
            ctx.font = '10px sans-serif';
            ctx.textAlign = 'right';
            for (let i = 0; i <= 4; i++) {
                const y = padding.top + (chartH * i / 4);
                ctx.beginPath();
                ctx.moveTo(padding.left, y);
                ctx.lineTo(w - padding.right, y);
                ctx.stroke();
                ctx.fillText((100 - i * 25) + '%', padding.left - 5, y + 3);
            }

            // X轴轮次标签（R1 始终位于最左，其余点标签按需显示）
            const totalPoints = dataPoints.length;
            let labelStep = 1;
            if (totalPoints > 15) labelStep = Math.floor(totalPoints / 10);
            if (labelStep < 1) labelStep = 1;
            ctx.textAlign = 'center';
            ctx.fillStyle = TEXT_COLOR;
            ctx.font = '9px sans-serif';
            for (let i = 0; i < totalPoints; i += labelStep) {
                const x = padding.left + (chartW * i / (totalPoints - 1 || 1));
                ctx.fillText('R' + dataPoints[i].round, x, h - padding.bottom + 12);
            }

            // 绘制折线（张力使用动态颜色）
            const dynamicTensionColor = getDynamicTensionColor();
            const keys = ['tension', 'lineOut', 'playerStamina', 'fishStamina'];
            const yPos = (val) => padding.top + chartH * (1 - val);
            keys.forEach(key => {
                ctx.strokeStyle = key === 'tension' ? dynamicTensionColor : LINE_COLORS[key];
                ctx.lineWidth = 2;
                ctx.beginPath();
                dataPoints.forEach((point, idx) => {
                    const x = padding.left + (chartW * idx / (totalPoints - 1 || 1));
                    const y = yPos(point[key]);
                    if (idx === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                });
                ctx.stroke();
            });

            // 图例（右上角）
            const legendX = w - padding.right - 110;
            const legendY = padding.top;
            ctx.font = '10px sans-serif';
            ctx.textAlign = 'left';
            keys.forEach((key, i) => {
                const y = legendY + i * 18;
                ctx.fillStyle = key === 'tension' ? dynamicTensionColor : LINE_COLORS[key];
                ctx.fillRect(legendX, y - 7, 12, 12);
                ctx.fillStyle = TEXT_COLOR;
                ctx.fillText(LINE_LABELS[key], legendX + 18, y + 2);
            });
        }

        // 更新数据（平坦省略 + R1 固定逻辑）
        function updateData() {
            const round = getCurrentRound();
            const percents = readPercentages();
            if (!round || !percents) return;

            if (dataPoints.length === 0) {
                // 首次记录
                dataPoints.push({ round, ...percents });
                lastRecordedRound = round;
            } else if (round !== lastRecordedRound) {
                // 轮次变化
                const last = dataPoints[dataPoints.length - 1];
                if (last.tension === percents.tension &&
                    last.lineOut === percents.lineOut &&
                    last.playerStamina === percents.playerStamina &&
                    last.fishStamina === percents.fishStamina) {
                    // 数据未变，仅更新轮次记忆
                    lastRecordedRound = round;
                } else {
                    // 数据有变，追加新点
                    dataPoints.push({ round, ...percents });
                    lastRecordedRound = round;

                    // 超出上限时裁剪：保留第一个（R1） + 最后 MAX-1 个
                    if (dataPoints.length > MAX_DATA_POINTS) {
                        const first = dataPoints[0];
                        const rest = dataPoints.slice(-(MAX_DATA_POINTS - 1));
                        dataPoints = [first, ...rest];
                    }
                }
            } else {
                // 轮次未变，更新最后一个点
                const last = dataPoints[dataPoints.length - 1];
                last.tension = percents.tension;
                last.lineOut = percents.lineOut;
                last.playerStamina = percents.playerStamina;
                last.fishStamina = percents.fishStamina;
            }

            drawChart();
        }

        function start() {
            if (!getStatusCard()) {
                setTimeout(start, 1000);
                return;
            }
            insertChart();
            if (chartInterval) clearInterval(chartInterval);
            chartInterval = setInterval(updateData, UPDATE_INTERVAL);
            updateData();
            console.log('[钓鱼实时波动图] 已启动（R1固定 + 动态色调）');
        }

        function stop() {
            if (chartInterval) {
                clearInterval(chartInterval);
                chartInterval = null;
            }
        }

        const domObserver = new MutationObserver(() => {
            const statusCard = getStatusCard();
            if (!statusCard && chartInserted) {
                if (canvas && canvas.parentNode) canvas.parentNode.remove();
                chartInserted = false;
                stop();
                dataPoints = [];
                lastRecordedRound = null;
                console.log('[钓鱼实时波动图] 已停止');
            } else if (statusCard && !chartInserted) {
                start();
            }
        });
        domObserver.observe(document.body, { childList: true, subtree: true });

        setTimeout(start, 800);
    })();
}
// 功能：鱼获卡片重量标记
function initFishWeightGlow() {
    (function() {
        'use strict';
        const WEIGHT_MARKS = [
            { min: 10000, border: '#FF1744', stripe: '#D50000', bg: '#B71C1C' },       // 血红色（绝命巨物）
            { min: 8000,  max: 9999,  border: '#FF5252', stripe: '#C62828', bg: '#B71C1C' }, // 深红（深渊巨兽）
            { min: 6000,  max: 7999,  border: '#FF8A80', stripe: '#D32F2F', bg: '#C62828' }, // 浅红（致命大鱼）
            { min: 5000,  max: 5999,  border: '#FFAB40', stripe: '#E65100', bg: '#BF360C' }, // 橙色（极度危险）
            { min: 4000,  max: 4999,  border: '#FFD740', stripe: '#F57C00', bg: '#E65100' }, // 琥珀（高危险）
            { min: 3000,  max: 3999,  border: '#FFD54F', stripe: '#F9A825', bg: '#F57F17' }, // 金黄（中等危险）
            { min: 2000,  max: 2999,  border: '#64B5F6', stripe: '#1E88E5', bg: '#1565C0' }, // 蓝色（大型）
            { min: 1000,  max: 1999,  border: '#81C784', stripe: '#388E3C', bg: '#2E7D32' }, // 绿色（中型）
            { min: 500,   max: 999,   border: '#90A4AE', stripe: '#546E7A', bg: '#37474F' }, // 灰色（小型）
            { min: 0,     max: 499,   border: '#B0BEC5', stripe: '#607D8B', bg: '#455A64' }, // 浅灰（幼鱼）
        ];
        function isFishCard(card) {
            return card.classList.contains('region-fish-card') ||
                   card.querySelector('.lucide-fish') !== null;
        }
        function getWeight(card) {
            const content = card.querySelector('.region-fish-card-content') || card;
            const textNodes = content.querySelectorAll('.text-xs.text-muted');
            for (const node of textNodes) {
                const text = node.textContent.trim();
                const match = text.match(/([\d,]+(?:\.\d+)?)\s*kg/i);
                if (match) {
                    const value = parseFloat(match[1].replace(/,/g, ''));
                    return isNaN(value) ? null : value;
                }
            }
            return null;
        }
        function getMark(weight) {
            for (const rule of WEIGHT_MARKS) {
                if (weight >= rule.min && weight <= (rule.max ?? Infinity)) {
                    return rule;
                }
            }
            return WEIGHT_MARKS[0];
        }
        function applyMark(card) {
            if (card.dataset.weightMarked) return;
            const weight = getWeight(card);
            if (weight === null) return;
            const mark = getMark(weight);
            if (!mark) return;
            card.style.borderLeft = `3px solid ${mark.stripe}`;
            card.style.paddingLeft = '4px';
            card.style.borderBottom = `2px solid ${mark.border}80`;
            card.style.background = `
                linear-gradient(180deg,
                    ${mark.bg}18 0%,
                    ${mark.bg}06 50%,
                    transparent 100%
                )
            `;
            card.dataset.weightMarked = 'true';
        }
        function processAll() {
            document.querySelectorAll('.region-fish-card, .square-item-card').forEach(card => {
                if (isFishCard(card)) applyMark(card);
            });
        }
        setTimeout(processAll, 500);
        const observer = new MutationObserver(() => processAll());
        observer.observe(document.body, { childList: true, subtree: true });
        console.log('[鱼获重量标记] 已启动（危险信号配色）');
    })();
}
// 功能：本周目标鱼 - 按场地聚合显示
function initWeeklyTarget() {
    (function() {
        'use strict';

        const PANEL_CLASS = 'weekly-spot-panel-v11';

        // 稀有度 → 颜色
        const RARITY_COLORS = {
            '传奇': '#DAA520',
            '传说': '#FF8C00',
            '罕见': '#B8860B',
            '稀有': '#CD853F',
            '少见': '#A0A0A0',
        };

        function getRarityColor(rarity) {
            return RARITY_COLORS[rarity] || '#475569';
        }

        // 构建鱼名 → {场地, 稀有度}
        function buildFishMap() {
            const map = new Map();
            if (typeof FISH_DATABASE === 'undefined') return map;

            const items = FISH_DATABASE.content || FISH_DATABASE;
            if (!items || !Array.isArray(items)) return map;

            items.forEach(item => {
                const name = (item.name || item['名称'] || '').trim();
                const rarity = item['稀有度'] || '';
                const details = item.details || item['详情'] || {};
                const spot = details['分布区域'] || '';
                if (name && spot) map.set(name, { spot, rarity });
            });

            return map;
        }

        const fishMap = buildFishMap();

        function getFishName(card) {
            const nameEl = card.querySelector('.item-name');
            if (!nameEl) return null;
            for (const node of nameEl.childNodes) {
                if (node.nodeType === 3 && node.textContent.trim()) {
                    return node.textContent.trim();
                }
            }
            return nameEl.textContent.trim();
        }

        function getWeeklyFishNames() {
            const cards = document.querySelectorAll('.weekly-target-fish-card');
            return [...new Set([...cards].map(getFishName).filter(Boolean))];
        }

        function groupBySpot(fishNames) {
            const map = new Map();
            fishNames.forEach(fishName => {
                const info = fishMap.get(fishName);
                if (!info) return;
                info.spot.split(/[,，、;；]/).map(s => s.trim()).filter(Boolean).forEach(s => {
                    if (!map.has(s)) map.set(s, []);
                    map.get(s).push({ name: fishName, rarity: info.rarity });
                });
            });
            return map;
        }

        // 创建场地卡片
        function createSpotCard(spotName, fishList) {
            const card = document.createElement('div');
            card.style.cssText = `
                border: 1px solid rgba(100, 116, 139, 0.15);
                background: rgba(241, 245, 249, 0.35);
                border-radius: 8px;
                padding: 10px 14px;
                min-width: 160px;
                flex: 1 1 auto;
            `;

            // 场地名
            const spotDiv = document.createElement('div');
            spotDiv.style.cssText = 'color:#334155;font-weight:700;font-size:0.9em;margin-bottom:6px;';
            spotDiv.textContent = spotName;
            card.appendChild(spotDiv);

            // 鱼名列表（带颜色）
            const fishDiv = document.createElement('div');
            fishDiv.style.cssText = 'font-size:0.8em;font-weight:500;line-height:1.8;';

            fishList.forEach((fish, index) => {
                const span = document.createElement('span');
                span.textContent = fish.name;
                span.style.cssText = `
                    color: ${getRarityColor(fish.rarity)};
                    font-weight: 700;
                `;
                fishDiv.appendChild(span);

                if (index < fishList.length - 1) {
                    const sep = document.createElement('span');
                    sep.textContent = '  ·  ';
                    sep.style.cssText = 'color:#94a3b8;font-weight:400;';
                    fishDiv.appendChild(sep);
                }
            });

            card.appendChild(fishDiv);
            return card;
        }

        // 渲染面板
        function renderSpotPanel() {
            const grid = document.querySelector('.weekly-target-fish-grid');
            if (!grid || document.querySelector('.' + PANEL_CLASS)) return;

            const fishNames = getWeeklyFishNames();
            if (fishNames.length === 0) return;

            const grouped = groupBySpot(fishNames);
            if (grouped.size === 0) return;

            requestAnimationFrame(() => {
                const panel = document.createElement('div');
                panel.className = 'card mt-sm ' + PANEL_CLASS;
                panel.style.cssText = 'padding:12px 14px;';

                const title = document.createElement('div');
                title.style.cssText = 'color:#64748b;font-size:0.78em;font-weight:600;margin-bottom:8px;';
                title.textContent = '本周目标鱼可钓场地';
                panel.appendChild(title);

                const spotGrid = document.createElement('div');
                spotGrid.style.cssText = 'display:flex;flex-wrap:wrap;gap:6px;';

                grouped.forEach((fishList, spotName) => {
                    spotGrid.appendChild(createSpotCard(spotName, fishList));
                });

                panel.appendChild(spotGrid);
                grid.parentNode.insertBefore(panel, grid.nextSibling);
            });
        }

        let timer = null;

        function init() {
            renderSpotPanel();

            const target = document.querySelector('.weekly-competition-panel') || document.body;
            const observer = new MutationObserver(() => {
                clearTimeout(timer);
                timer = setTimeout(() => {
                    const old = document.querySelector('.' + PANEL_CLASS);
                    if (old) old.remove();
                    renderSpotPanel();
                }, 250);
            });
            observer.observe(target, { childList: true, subtree: true });
        }

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：上鱼记录统计总结 v12（起始时间并入标题行）
// 注册名：catchSummary
function initCatchSummary() {
    (function() {
        'use strict';

        const PANEL_ID = 'catch-summary-panel-v12';

        const GRADE_COLORS = {
            '不达标': '#94a3b8',
            '达标': '#4ade80',
            '稀有': '#60a5fa',
            '罕见': '#fbbf24',
            '传说': '#f87171',
        };
        const GRADE_ORDER = ['不达标', '达标', '稀有', '罕见', '传说'];

        const FISH_COLORS = [
            '#38bdf8', '#60a5fa', '#3b82f6', '#1d4ed8',
            '#4ade80', '#22c55e', '#16a34a',
            '#fbbf24', '#f59e0b', '#d97706',
            '#f87171', '#ef4444', '#dc2626',
            '#a78bfa', '#8b5cf6', '#7c3aed',
            '#fb923c', '#f97316', '#ea580c',
        ];

        function parseCard(card) {
            const isCatch = card.classList.contains('message-card--catch');
            const isReeling = card.classList.contains('message-card--reeling');
            if (!isCatch && !isReeling) return null;

            const titleEl = card.querySelector('.lz-ct-fish-title') || card.querySelector('.message-title');
            let fishName = null;
            if (titleEl) {
                fishName = titleEl.textContent.trim();
            }

            const infoRow = card.querySelector('.lz-ct-info-row');
            let grade = null, weight = null;
            if (infoRow) {
                const tagEl = infoRow.querySelector('.lz-ct-tag');
                const specEl = infoRow.querySelector('.lz-ct-spec');
                if (tagEl) grade = tagEl.textContent.trim();
                if (specEl) {
                    const wm = specEl.textContent.match(/([\d,.]+)\s*kg/);
                    if (wm) weight = parseFloat(wm[1].replace(/,/g, ''));
                }
            } else {
                const detailEl = card.querySelector('.text-sm.text-muted');
                const detailText = detailEl ? detailEl.textContent.trim() : '';
                const gm = detailText.match(/(不达标|达标|稀有|罕见|传说)/);
                if (gm) grade = gm[1];
                const wm = detailText.match(/([\d,.]+)\s*kg/);
                if (wm) weight = parseFloat(wm[1].replace(/,/g, ''));
            }

            const timeEl = card.querySelector('.text-xs.text-muted');
            let timeStr = null;
            if (timeEl) {
                const tm = timeEl.textContent.match(/(\d{4}\/\d{2}\/\d{2}\s+\d{2}:\d{2}:\d{2})/);
                if (tm) timeStr = tm[1];
            }

            const intervalEl = card.querySelector('.catch-interval');
            let interval = null;
            if (intervalEl) {
                const im = intervalEl.textContent.match(/(\d+)/);
                if (im) interval = parseInt(im[1]);
            }

            return { type: isCatch ? '上鱼' : '脱钩', fishName, grade, weight, interval, timeStr };
        }

        function computeStats(cards) {
            const s = {
                catches: 0, failures: 0, grades: {}, fishMap: {},
                weights: [], intervals: [], maxW: 0, maxFish: '', firstCatchTime: null,
            };

            cards.forEach(c => {
                const d = parseCard(c);
                if (!d) return;
                if (d.type === '上鱼') {
                    s.catches++;
                    if (!s.firstCatchTime && d.timeStr) {
                        s.firstCatchTime = d.timeStr;
                    }
                    if (d.grade) s.grades[d.grade] = (s.grades[d.grade] || 0) + 1;
                    if (d.fishName) s.fishMap[d.fishName] = (s.fishMap[d.fishName] || 0) + 1;
                    if (d.weight && d.weight > 0) {
                        s.weights.push(d.weight);
                        if (d.weight > s.maxW) { s.maxW = d.weight; s.maxFish = d.fishName || ''; }
                    }
                } else s.failures++;
                if (d.interval) s.intervals.push(d.interval);
            });

            s.total = s.catches + s.failures;
            s.rate = s.total > 0 ? Math.round(s.catches / s.total * 100) : 0;
            s.avgInterval = s.intervals.length > 0
                ? Math.round(s.intervals.reduce((a, b) => a + b, 0) / s.intervals.length) : 0;
            s.allFish = Object.entries(s.fishMap).sort((a, b) => b[1] - a[1]);
            return s;
        }

        function createPanel(stats) {
            const old = document.getElementById(PANEL_ID);
            if (old) old.remove();

            const panel = document.createElement('div');
            panel.id = PANEL_ID;
            panel.className = 'card mt-sm';
            panel.style.cssText = 'padding:12px 14px;';

            // 标题行：左=本次钓行统计+起始时间，右=次数+上鱼率
            const header = document.createElement('div');
            header.style.cssText = 'display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;';
            const leftPart = stats.firstCatchTime
                ? `<span class="text-sm" style="font-weight:700;">本次钓行统计</span><span class="text-xs text-muted" style="margin-left:8px;">${stats.firstCatchTime}</span>`
                : `<span class="text-sm" style="font-weight:700;">本次钓行统计</span>`;
            const rightPart = `<span class="text-xs text-muted">${stats.total}次 · 上鱼率${stats.rate}%</span>`;
            header.innerHTML = `<div>${leftPart}</div><div>${rightPart}</div>`;
            panel.appendChild(header);

            const grid = document.createElement('div');
            grid.style.cssText = 'display:flex;gap:8px;margin-bottom:10px;';
            grid.innerHTML = `
                <div style="flex:1;text-align:center;"><div style="color:#60a5fa;font-size:1.1em;font-weight:800;">${stats.catches}</div><div class="text-xs text-muted">成功</div></div>
                <div style="flex:1;text-align:center;"><div style="color:#f87171;font-size:1.1em;font-weight:800;">${stats.failures}</div><div class="text-xs text-muted">脱钩</div></div>
                <div style="flex:1;text-align:center;"><div style="color:#fbbf24;font-size:1.1em;font-weight:800;">${stats.maxW.toFixed(1)}</div><div class="text-xs text-muted">最大kg</div></div>
                <div style="flex:1;text-align:center;"><div style="color:#4ade80;font-size:1.1em;font-weight:800;">${stats.avgInterval}</div><div class="text-xs text-muted">均口分</div></div>
            `;
            panel.appendChild(grid);

            // 等级分布条
            const gradeBar = document.createElement('div');
            gradeBar.className = 'catch-rating-bar mt-sm';
            GRADE_ORDER.forEach(g => {
                const count = stats.grades[g] || 0;
                const pct = stats.catches > 0 ? (count / stats.catches * 100) : 0;
                if (count > 0) {
                    const seg = document.createElement('div');
                    seg.style.cssText = `width:${pct}%;background:${GRADE_COLORS[g]};`;
                    gradeBar.appendChild(seg);
                }
            });
            panel.appendChild(gradeBar);

            const gradeLabels = document.createElement('div');
            gradeLabels.style.cssText = 'display:flex;flex-wrap:wrap;gap:10px;font-size:0.68em;margin-top:4px;margin-bottom:8px;';
            gradeLabels.innerHTML = GRADE_ORDER.filter(g => stats.grades[g]).map(g =>
                `<span><span style="color:${GRADE_COLORS[g]};font-weight:600;">${g}</span> <span class="text-muted">${stats.grades[g]}</span></span>`
            ).join('');
            panel.appendChild(gradeLabels);

            // 鱼种分布条
            if (stats.allFish.length > 0) {
                const fishBar = document.createElement('div');
                fishBar.className = 'catch-rating-bar mt-sm';
                stats.allFish.forEach((f, i) => {
                    const pct = stats.catches > 0 ? (f[1] / stats.catches * 100) : 0;
                    if (pct > 0) {
                        const seg = document.createElement('div');
                        seg.style.cssText = `width:${pct}%;background:${FISH_COLORS[i % FISH_COLORS.length]};`;
                        seg.title = `${f[0]}: ${f[1]}条`;
                        fishBar.appendChild(seg);
                    }
                });
                panel.appendChild(fishBar);

                const fishLabels = document.createElement('div');
                fishLabels.style.cssText = 'display:flex;flex-wrap:wrap;gap:10px;font-size:0.68em;margin-top:4px;';
                fishLabels.innerHTML = stats.allFish.map((f, i) =>
                    `<span><span style="color:${FISH_COLORS[i % FISH_COLORS.length]};font-weight:600;">${f[0]}</span> <span class="text-muted">${f[1]}</span></span>`
                ).join('');
                panel.appendChild(fishLabels);
            }

            return panel;
        }

        function insertPanel() {
            const cards = document.querySelectorAll('.message-card--catch, .message-card--reeling');
            if (cards.length === 0) {
                const old = document.getElementById(PANEL_ID);
                if (old) old.remove();
                return;
            }
            const stats = computeStats(cards);
            if (stats.catches === 0) return;
            const panel = createPanel(stats);
            const target = document.querySelector('.flex.items-center.justify-between.gap-sm.mt-sm');
            if (target) target.parentNode.insertBefore(panel, target.nextSibling);
        }

        let timer = null;
        function init() {
            insertPanel();
            timer = setInterval(insertPanel, 2000);
        }
        window.addEventListener('beforeunload', function() { if (timer) clearInterval(timer); });

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：鱼体力UI增强
function initFishStaminaUI() {
    (function() {
        'use strict';

        const CONFIG = {
            COLORS: ['#FF0000', '#CC00FF', '#00FF00', '#0066FF', '#FFDD00'],
            POINTS_PER_LAYER: 20,
            FLASH_DURATION: 200
        };

        function findFishStaminaCard() {
            const cards = document.querySelectorAll('.fishing-metric-card');
            for (const card of cards) {
                const label = card.querySelector('.fishing-metric-label');
                if (label && label.textContent.includes('鱼体力')) return card;
            }
            return null;
        }

        function initFishStaminaCard(card) {
            const originalFill = card.querySelector('.progress-bar-fill');
            if (!originalFill) return;
            originalFill.style.display = 'none';

            const progressBar = card.querySelector('.fishing-metric-progress');
            if (!progressBar) return;
            progressBar.style.position = 'relative';

            const bottomBar = document.createElement('div');
            Object.assign(bottomBar.style, {
                position: 'absolute', top: '0', left: '0',
                width: '100%', height: '100%', borderRadius: 'inherit'
            });
            progressBar.appendChild(bottomBar);

            const topBar = document.createElement('div');
            Object.assign(topBar.style, {
                position: 'absolute', top: '0', left: '0',
                height: '100%', borderRadius: 'inherit',
                transition: 'width 0.1s ease'
            });
            progressBar.appendChild(topBar);

            let maxStamina = 0, previousStamina = 0;

            function getLayerColor(stamina) {
                return CONFIG.COLORS[Math.floor(stamina / CONFIG.POINTS_PER_LAYER) % CONFIG.COLORS.length];
            }

            function getNextLayerColor(stamina) {
                const idx = Math.floor(stamina / CONFIG.POINTS_PER_LAYER) - 1;
                return CONFIG.COLORS[idx < 0 ? CONFIG.COLORS.length - 1 : idx % CONFIG.COLORS.length];
            }

            function updateBars(stamina) {
                const inLayer = stamina % CONFIG.POINTS_PER_LAYER;
                bottomBar.style.background = getNextLayerColor(stamina);
                topBar.style.background = getLayerColor(stamina);
                topBar.style.width = (inLayer / CONFIG.POINTS_PER_LAYER * 100) + '%';
            }

            function flash(oldStamina, newStamina) {
                const oldW = (oldStamina % CONFIG.POINTS_PER_LAYER) / CONFIG.POINTS_PER_LAYER * 100;
                const newW = (newStamina % CONFIG.POINTS_PER_LAYER) / CONFIG.POINTS_PER_LAYER * 100;
                const oldL = Math.floor(oldStamina / CONFIG.POINTS_PER_LAYER);
                const newL = Math.floor(newStamina / CONFIG.POINTS_PER_LAYER);

                for (let i = newL; i <= oldL; i++) {
                    setTimeout(() => {
                        const f = document.createElement('div');
                        Object.assign(f.style, {
                            position: 'absolute', top: '0', right: '0',
                            height: '100%', background: 'white', opacity: '0',
                            zIndex: '10', pointerEvents: 'none', borderRadius: 'inherit'
                        });
                        if (i === oldL && i === newL) {
                            f.style.width = (oldW - newW) + '%';
                            f.style.right = (100 - oldW) + '%';
                        } else if (i === oldL) {
                            f.style.width = oldW + '%';
                            f.style.right = '0%';
                        } else if (i === newL) {
                            f.style.width = (100 - newW) + '%';
                            f.style.right = newW + '%';
                        } else {
                            f.style.width = '100%';
                            f.style.right = '0%';
                        }
                        progressBar.appendChild(f);
                        f.animate([
                            { opacity: 0 },
                            { opacity: 0.9, offset: 0.3 },
                            { opacity: 0.5, offset: 0.6 },
                            { opacity: 0 }
                        ], { duration: CONFIG.FLASH_DURATION, easing: 'ease-out' }).onfinish = () => f.remove();
                    }, (oldL - i) * 50);
                }
            }

            function parseAndUpdate() {
                const valueElem = card.querySelector('.fishing-metric-value');
                if (!valueElem) return;
                const match = valueElem.textContent.trim().match(/([\d.]+)\s*\/\s*([\d.]+)/);
                if (!match) return;
                const cur = parseFloat(match[1]), max = parseFloat(match[2]);
                if (Math.abs(max - maxStamina) > 0.01) {
                    maxStamina = max; previousStamina = cur; updateBars(cur); return;
                }
                if (cur < previousStamina) flash(previousStamina, cur);
                previousStamina = cur; updateBars(cur);
            }

            const valueElem = card.querySelector('.fishing-metric-value');
            if (valueElem) {
                new MutationObserver(parseAndUpdate).observe(valueElem, {
                    characterData: true, subtree: true, childList: true
                });
            }
            parseAndUpdate();
        }

        function processAll() {
            const card = findFishStaminaCard();
            if (card && !card.dataset.staminaUIEnhanced) {
                card.dataset.staminaUIEnhanced = 'true';
                initFishStaminaCard(card);
            }
        }

        processAll();
        new MutationObserver(processAll).observe(document.body, { childList: true, subtree: true });
    })();
}
// 功能：实时状态动态边框
function initDynamicBorder() {
    (function() {
        'use strict';

        // 注入样式
        if (!document.getElementById('dynamic-border-style')) {
            const style = document.createElement('style');
            style.id = 'dynamic-border-style';
            style.textContent = `
                .fishing-compact-card:has(.fishing-metric-grid) {
                    position: relative !important;
                    border-radius: 8px !important;
                }
                .fishing-compact-card:has(.fishing-metric-grid)::before {
                    content: '' !important;
                    position: absolute !important;
                    inset: -2px !important;
                    border-radius: inherit !important;
                    padding: 2px !important;
                    background: var(--db-gradient) !important;
                    background-size: 400% 100% !important;
                    mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0) !important;
                    mask-composite: exclude !important;
                    -webkit-mask-composite: xor !important;
                    pointer-events: none !important;
                    opacity: var(--db-opacity, 0.7) !important;
                    filter: brightness(var(--db-brightness, 1.2)) saturate(var(--db-saturation, 1.5)) !important;
                    animation: dbGradientFlow 3s linear infinite !important;
                }
                .fishing-compact-card:has(.fishing-metric-grid)::after {
                    content: '' !important;
                    position: absolute !important;
                    inset: -4px !important;
                    border-radius: inherit !important;
                    background: var(--db-glow, rgba(0,212,255,0.3)) !important;
                    background-size: 400% 100% !important;
                    filter: blur(8px) !important;
                    z-index: -1 !important;
                    opacity: var(--db-glow-opacity, 0.4) !important;
                    animation: dbGradientFlow 3s linear infinite !important;
                    pointer-events: none !important;
                }
                @keyframes dbGradientFlow {
                    0% { background-position: 0% 50%; }
                    100% { background-position: 400% 50%; }
                }
            `;
            document.head.appendChild(style);
        }

        function getPercent(label) {
            const cards = document.querySelectorAll('.fishing-metric-card');
            for (const card of cards) {
                if (card.querySelector('.fishing-metric-label')?.textContent?.includes(label)) {
                    const fill = card.querySelector('.progress-bar-fill');
                    if (fill) return parseFloat(fill.style.width) || 0;
                }
            }
            return 0;
        }

        function buildGradient(tension, stamina) {
            const t = tension > 80 ? '#ff1744, #ff6d00' :
                      tension > 50 ? '#ff9100, #ffd740' :
                      tension > 20 ? '#ffd740, #00e676' : '#00e676, #00e5ff';
            const s = stamina > 70 ? '#d500f9, #ff1744' :
                      stamina > 40 ? '#ff6d00, #ff9100' :
                      stamina > 15 ? '#ffd740, #00e676' : '#00e676, #00e5ff';
            return `linear-gradient(90deg, ${t}, ${s})`;
        }

        function buildGlow(tension) {
            return tension > 80 ? 'rgba(255,23,68,0.4)' :
                   tension > 50 ? 'rgba(255,145,0,0.35)' :
                   tension > 20 ? 'rgba(255,215,64,0.3)' : 'rgba(0,229,255,0.3)';
        }

        function update() {
            const card = document.querySelector('.fishing-compact-card:has(.fishing-metric-grid)');
            if (!card) return;
            const tension = getPercent('张力');
            const stamina = getPercent('鱼体力');
            const style = card.style;
            style.setProperty('--db-gradient', buildGradient(tension, stamina));
            style.setProperty('--db-glow', buildGlow(tension));
            style.setProperty('--db-opacity', Math.min(0.5 + tension / 100, 0.9));
            style.setProperty('--db-brightness', Math.min(1 + tension / 200, 1.5));
            style.setProperty('--db-saturation', Math.min(1.2 + tension / 150, 1.8));
            style.setProperty('--db-glow-opacity', Math.min(0.15 + tension / 120, 0.6));
        }

        setInterval(update, 500);
        new MutationObserver(update).observe(document.body, { childList: true, subtree: true, attributes: true });
        update();
    })();
}
// 功能：专精技能加成汇总
function initSpecializationSummary() {
    (function() {
        'use strict';
        const PANEL_CLASS = 'spec-summary-panel';
        function parseEffect(text) {
            if (!text) return null;

            // 匹配 "每级xxx +/-数字" 或 "每级xxx +/-数字%"
            let match = text.match(/每级(.+?)\s*([+-]?\d+\.?\d*)\s*(%?)/);
            if (match) {
                return {
                    name: match[1].trim(),
                    value: parseFloat(match[2]),
                    unit: match[3] || '',
                };
            }
            // 匹配固定值格式 "xxx +/-数字" 或 "xxx +/-数字%"
            // 如 "拉鱼速度 +6.0%", "体力压力 -10.0%"
            match = text.match(/^(.+?)\s*([+-]?\d+\.?\d*)\s*(%?)$/);
            if (match) {
                return {
                    name: match[1].trim(),
                    value: parseFloat(match[2]),
                    unit: match[3] || '',
                };
            }

            // 其他格式跳过
            return null;
        }

        // 解析单个技能卡
        function parseSkill(card) {
            const head = card.querySelector('.specialization-skill-head');
            if (!head) return null;

            const nameEl = head.querySelector('strong');
            const name = nameEl ? nameEl.textContent.trim() : '';

            // 已学等级
            const span = head.querySelector('span');
            if (!span) return null;
            const parts = span.textContent.trim().split('/');
            const learned = parseInt(parts[0]);
            if (isNaN(learned) || learned === 0) return null;

            // 效果列表
            const effects = card.querySelectorAll('.specialization-skill-effects p');
            const parsed = [];
            effects.forEach(p => {
                const effect = parseEffect(p.textContent.trim());
                if (effect) parsed.push(effect);
            });

            return { name, learned, effects: parsed };
        }

        // 汇总一个专精树
        function summarizeTree(tree) {
            const cards = tree.querySelectorAll('.specialization-skill:not(.is-locked)');
            const summary = {};

            cards.forEach(card => {
                const skill = parseSkill(card);
                if (!skill) return;

                skill.effects.forEach(e => {
                    const key = e.name;
                    if (!summary[key]) summary[key] = { totalValue: 0, unit: e.unit };
                    summary[key].totalValue += e.value * skill.learned;
                });
            });

            return summary;
        }

        // 创建汇总卡片
        function createSummaryCard(treeTitle, summary) {
            const entries = Object.entries(summary);
            if (entries.length === 0) return null;

            const card = document.createElement('div');
            card.className = 'card mt-sm ' + PANEL_CLASS;
            card.style.cssText = 'padding:8px 12px;font-size:0.75em;';

            const title = document.createElement('div');
            title.style.cssText = 'color:#2F343B;font-weight:600;margin-bottom:4px;';
            title.textContent = `${treeTitle} 已学加成`;
            card.appendChild(title);

            entries.forEach(([name, info]) => {
                const row = document.createElement('div');
                row.style.cssText = 'display:flex;justify-content:space-between;padding:2px 0;';
                row.innerHTML = `
                    <span style="color:#7C828A;">${name}</span>
                    <span style="color:#17A12D;font-weight:600;">+${info.totalValue.toFixed(3)}${info.unit}</span>
                `;
                card.appendChild(row);
            });

            return card;
        }

        // 处理所有专精树
        function processAll() {
            const trees = document.querySelectorAll('.specialization-tree');
            trees.forEach(tree => {
                if (tree.querySelector('.' + PANEL_CLASS)) return;

                const titleEl = tree.querySelector('.specialization-tree-title');
                if (!titleEl) return;

                const h3 = titleEl.querySelector('h3');
                const treeTitle = h3 ? h3.textContent.trim() : '';

                const summary = summarizeTree(tree);
                const card = createSummaryCard(treeTitle, summary);
                if (card) {
                    titleEl.parentNode.insertBefore(card, titleEl.nextSibling);
                }
            });
        }

        function init() {
            processAll();
            const observer = new MutationObserver(() => processAll());
            observer.observe(document.body, { childList: true, subtree: true });
        }

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：专精模拟器
function initSpecializationSim() {
    (function() {
        'use strict';

        const SIM_BTN_ID = 'spec-sim-toggle';
        const ACTIVE_CLASS = 'spec-sim-active';
        let simMode = false;
        let totalUsed = 0;
        let origPoints = 0;

        function getActiveTree() {
            const trees = document.querySelectorAll('.specialization-tree');
            for (const t of trees) {
                if (t.offsetParent !== null) return t;
            }
            return trees[0];
        }

        function addSimButton() {
            const tabs = document.querySelector('.scroll-row.specialization-tabs');
            if (!tabs || document.getElementById(SIM_BTN_ID)) return;
            const btn = document.createElement('button');
            btn.id = SIM_BTN_ID;
            btn.className = 'tab';
            btn.textContent = '模拟';
            btn.style.cssText = 'color:#fbbf24;font-weight:700;';
            btn.addEventListener('click', toggleSim);
            tabs.appendChild(btn);
        }

        function toggleSim() {
            simMode = !simMode;
            const btn = document.getElementById(SIM_BTN_ID);
            const tree = getActiveTree();

            if (simMode) {
                btn.classList.add('tab-active');
                btn.style.background = '#2563eb'; btn.style.color = '#fff';
                totalUsed = 0;
                // 保存原始点数
                const strong = tree.querySelector('.specialization-tree-title strong');
                origPoints = strong ? parseInt(strong.textContent) || 0 : 0;
                enableSim(tree);
            } else {
                btn.classList.remove('tab-active');
                btn.style.background = ''; btn.style.color = '#fbbf24';
                disableSim(tree);
                // 恢复原始点数
                const strong = tree.querySelector('.specialization-tree-title strong');
                if (strong) {
                    strong.textContent = `${origPoints} 点`;
                    strong.style.color = '';
                }
            }
        }

        function getCost(btn) {
            const text = btn.textContent.trim();
            const m = text.match(/学习\s+(\d+)\s+点/);
            return m ? parseInt(m[1]) : 1;
        }

        function enableSim(tree) {
            if (!tree) return;
            tree.classList.add(ACTIVE_CLASS);
            tree.style.border = '2px solid #2563eb';
            tree.style.borderRadius = '8px';

            const buttons = tree.querySelectorAll('.specialization-skill .btn-primary');
            buttons.forEach(btn => {
                btn.dataset.origDisabled = btn.disabled;
                btn.disabled = false;
                btn.addEventListener('click', onSimClick, true);
            });
        }

        function disableSim(tree) {
            if (!tree) return;
            tree.classList.remove(ACTIVE_CLASS);

            const buttons = tree.querySelectorAll('.specialization-skill .btn-primary');
            buttons.forEach(btn => {
                btn.removeEventListener('click', onSimClick, true);
                if (btn.dataset.origDisabled === 'true') btn.disabled = true;
            });

            tree.style.border = totalUsed > 0 ? '2px solid rgba(37,99,235,0.4)' : '';
            if (totalUsed > 0) setTimeout(() => { tree.style.border = ''; }, 3000);
        }

        function onSimClick(e) {
            e.preventDefault();
            e.stopPropagation();

            const btn = e.currentTarget;
            const card = btn.closest('.specialization-skill');
            if (!card) return;

            const head = card.querySelector('.specialization-skill-head');
            const span = head?.querySelector('span');
            if (!span) return;

            const [cur, max] = span.textContent.trim().split('/').map(n => parseInt(n) || 0);
            if (cur >= max) return;

            const cost = getCost(btn);
            totalUsed += cost;

            span.textContent = `${cur + 1}/${max}`;
            if (cur + 1 >= max) {
                btn.textContent = '已学会';
                btn.disabled = true;
            }

            const tree = card.closest('.specialization-tree');
            const strong = tree.querySelector('.specialization-tree-title strong');
            if (strong) {
                strong.textContent = `${origPoints + totalUsed} 点`;
                strong.style.color = '#fbbf24';
            }
        }

        function watchTabs() {
            const tabs = document.querySelector('.scroll-row.specialization-tabs');
            if (!tabs) return;
            tabs.addEventListener('click', (e) => {
                const tab = e.target.closest('.tab');
                if (!tab || tab.id === SIM_BTN_ID) return;
                setTimeout(() => {
                    if (simMode) {
                        const prev = document.querySelector('.' + ACTIVE_CLASS);
                        if (prev) disableSim(prev);
                        totalUsed = 0;
                        const tree = getActiveTree();
                        const strong = tree.querySelector('.specialization-tree-title strong');
                        origPoints = strong ? parseInt(strong.textContent) || 0 : 0;
                        enableSim(tree);
                    }
                }, 150);
            });
        }

        function init() {
            addSimButton();
            watchTabs();
            new MutationObserver(addSimButton).observe(document.body, { childList: true, subtree: true });
        }

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：委托/高难排序（可交排前，已交付排后）
function initSortChallenges() {
    (function() {
        'use strict';

        const SORTED_FLAG = 'data-challenge-sorted';

        function getSubmitCount(card) {
            const progress = card.querySelector('.task-progress');
            if (!progress) return 0;
            const label = progress.getAttribute('aria-label') || '';
            const m = label.match(/可交\s+(\d+)\//);
            return m ? parseInt(m[1]) : 0;
        }

        function isDelivered(card) {
            // 查找 .license-owned 标记 "已交付"
            const owned = card.querySelector('.license-owned');
            return owned && owned.textContent.includes('已交付');
        }

        function sortSection(section) {
            if (!section || section.getAttribute(SORTED_FLAG) === '1') return;
            section.setAttribute(SORTED_FLAG, '1');

            const list = section.querySelector('.card-list');
            if (!list) return;

            const cards = [...list.querySelectorAll(':scope > .card')];
            if (cards.length < 2) return;

            // 分三组
            const submitable = [];    // 可交 > 0
            const normal = [];        // 可交 = 0 且未交付
            const delivered = [];     // 已交付

            cards.forEach((card, i) => {
                const count = getSubmitCount(card);
                const done = isDelivered(card);
                if (done) {
                    delivered.push({ card, index: i });
                } else if (count > 0) {
                    submitable.push({ card, count, index: i });
                } else {
                    normal.push({ card, index: i });
                }
            });

            // 可交组：按数量降序，同数量按原序
            submitable.sort((a, b) => b.count - a.count || a.index - b.index);
            // 普通组：按原序
            normal.sort((a, b) => a.index - b.index);
            // 已交付组：按原序
            delivered.sort((a, b) => a.index - b.index);

            const sorted = [
                ...submitable.map(s => s.card),
                ...normal.map(s => s.card),
                ...delivered.map(s => s.card)
            ];

            sorted.forEach(card => list.appendChild(card));
        }

        function sortAll() {
            const sections = document.querySelectorAll('.guild-section');
            sections.forEach(section => {
                const title = section.querySelector('.section-title');
                if (!title) return;
                const text = title.textContent;
                if (text.includes('每日委托') || text.includes('高难挑战')) {
                    sortSection(section);
                }
            });
        }

        function init() {
            sortAll();
            new MutationObserver(() => sortAll()).observe(document.body, { childList: true, subtree: true });
        }

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：排行榜美化
function initRankingStyle() {
    (function() {
        'use strict';

        const STYLED_FLAG = 'data-ranking-styled';

        function injectStyles() {
            if (document.getElementById('lz-ranking-styles')) return;
            const style = document.createElement('style');
            style.id = 'lz-ranking-styles';
            style.textContent = `
                .ranking-list {
                    display: flex;
                    flex-direction: column;
                    gap: 6px;
                }

                .ranking-item {
                    position: relative;
                    border-radius: 8px !important;
                    padding: 12px 16px !important;
                    background: #fff !important;
                    border: 1px solid #e2e8f0 !important;
                    border-left: none !important;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.04) !important;
                    overflow: hidden;
                    transition: transform 0.15s ease, box-shadow 0.15s ease;
                }

                .ranking-item::after {
                    content: '';
                    position: absolute;
                    inset: -1px;
                    border-radius: 8px;
                    opacity: 0;
                    transition: opacity 0.3s ease;
                    pointer-events: none;
                    z-index: 0;
                }
                .ranking-item:hover::after { opacity: 1; }

                .ranking-item::before {
                    content: '';
                    position: absolute;
                    left: 0;
                    top: 8px;
                    bottom: 8px;
                    width: 3px;
                    border-radius: 0 2px 2px 0;
                    z-index: 1;
                }

                /* 第1名 */
                .ranking-item.rank-1 {
                    background: linear-gradient(135deg, #fff5f5 0%, #ffeded 100%) !important;
                    border-color: #ec8b8d !important;
                }
                .ranking-item.rank-1::before { background: #d46b6e; }
                .ranking-item.rank-1::after {
                    opacity: 1;
                    box-shadow: 0 0 16px 3px rgba(212,107,110,0.20);
                    animation: lz-glow-pink 3s ease-in-out infinite;
                }
                .ranking-item.rank-1:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 4px 16px rgba(212,107,110,0.15) !important;
                }

                /* 第2名 */
                .ranking-item.rank-2 {
                    background: linear-gradient(135deg, #fffaf2 0%, #fff5e6 100%) !important;
                    border-color: #dbb75d !important;
                }
                .ranking-item.rank-2::before { background: #c49a3c; }
                .ranking-item.rank-2::after {
                    opacity: 1;
                    box-shadow: 0 0 14px 2px rgba(196,154,60,0.18);
                    animation: lz-glow-gold 3.5s ease-in-out infinite;
                }
                .ranking-item.rank-2:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 4px 14px rgba(196,154,60,0.14) !important;
                }

                /* 第3名 */
                .ranking-item.rank-3 {
                    background: linear-gradient(135deg, #f5f8fd 0%, #eef3fb 100%) !important;
                    border-color: #7fa8e0 !important;
                }
                .ranking-item.rank-3::before { background: #5a82c8; }
                .ranking-item.rank-3::after {
                    opacity: 1;
                    box-shadow: 0 0 13px 2px rgba(90,130,200,0.16);
                    animation: lz-glow-blue 4s ease-in-out infinite;
                }
                .ranking-item.rank-3:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 4px 14px rgba(90,130,200,0.12) !important;
                }

                /* 第4-10名 */
                .ranking-item.rank-4,
                .ranking-item.rank-5,
                .ranking-item.rank-6,
                .ranking-item.rank-7,
                .ranking-item.rank-8,
                .ranking-item.rank-9,
                .ranking-item.rank-10 {
                    background: #fff !important;
                    border-color: #e2e8f0 !important;
                }
                .ranking-item.rank-4::before,
                .ranking-item.rank-5::before,
                .ranking-item.rank-6::before,
                .ranking-item.rank-7::before,
                .ranking-item.rank-8::before,
                .ranking-item.rank-9::before,
                .ranking-item.rank-10::before { background: #92B9F7; }
                .ranking-item.rank-4::after,
                .ranking-item.rank-5::after,
                .ranking-item.rank-6::after,
                .ranking-item.rank-7::after,
                .ranking-item.rank-8::after,
                .ranking-item.rank-9::after,
                .ranking-item.rank-10::after {
                    opacity: 0.7;
                    box-shadow: 0 0 10px 1px rgba(148,163,184,0.18);
                    animation: lz-glow-white 4.5s ease-in-out infinite;
                }
                .ranking-item.rank-4:hover,
                .ranking-item.rank-5:hover,
                .ranking-item.rank-6:hover,
                .ranking-item.rank-7:hover,
                .ranking-item.rank-8:hover,
                .ranking-item.rank-9:hover,
                .ranking-item.rank-10:hover {
                    transform: translateY(-1px);
                    box-shadow: 0 4px 12px rgba(0,0,0,0.08) !important;
                }

                /* 其他 */
                .ranking-item:not(.rank-1):not(.rank-2):not(.rank-3):not(.rank-4):not(.rank-5):not(.rank-6):not(.rank-7):not(.rank-8):not(.rank-9):not(.rank-10) {
                    background: #fff !important;
                    border-color: #e2e8f0 !important;
                }
                .ranking-item:not(.rank-1):not(.rank-2):not(.rank-3):not(.rank-4):not(.rank-5):not(.rank-6):not(.rank-7):not(.rank-8):not(.rank-9):not(.rank-10)::before { background: #85DBA8; }
                .ranking-item:not(.rank-1):not(.rank-2):not(.rank-3):not(.rank-4):not(.rank-5):not(.rank-6):not(.rank-7):not(.rank-8):not(.rank-9):not(.rank-10)::after {
                    opacity: 0.5;
                    box-shadow: 0 0 8px 1px rgba(148,163,184,0.12);
                    animation: lz-glow-white 5s ease-in-out infinite;
                }

                /* 排名数字 */
                .ranking-rank {
                    position: relative;
                    z-index: 2;
                    font-weight: 700 !important;
                    min-width: 30px !important;
                    font-size: 0.95em !important;
                    color: #94a3b8 !important;
                }
                .ranking-item.rank-1 .ranking-rank { color: #c45a5d !important; font-size: 1.05em !important; }
                .ranking-item.rank-2 .ranking-rank { color: #b88930 !important; font-size: 1.02em !important; }
                .ranking-item.rank-3 .ranking-rank { color: #4e74b8 !important; }
                .ranking-item.rank-4 .ranking-rank,
                .ranking-item.rank-5 .ranking-rank,
                .ranking-item.rank-6 .ranking-rank,
                .ranking-item.rank-7 .ranking-rank,
                .ranking-item.rank-8 .ranking-rank,
                .ranking-item.rank-9 .ranking-rank,
                .ranking-item.rank-10 .ranking-rank { color: #6b9edb !important; }
                .ranking-item:not(.rank-1):not(.rank-2):not(.rank-3):not(.rank-4):not(.rank-5):not(.rank-6):not(.rank-7):not(.rank-8):not(.rank-9):not(.rank-10) .ranking-rank { color: #5ca873 !important; }

                /* 鱼名保持原样 */
                .ranking-name { position: relative; z-index: 2; }

                /* 横线在鱼种行上方居中 */
                .lz-strike-top {
                    display: block;
                    height: 1px;
                    margin: 0 auto 4px auto;
                    width: 60%;
                    background: rgba(220, 38, 38, 0.45);
                }

                /* 鱼种+尺寸 */
                .ranking-detail {
                    position: relative;
                    z-index: 2;
                    font-size: 0.82em !important;
                }
                .ranking-detail .lz-fish-name {
                    color: #334155;
                    font-weight: 500;
                }
                .ranking-detail .lz-fish-size {
                    color: #94a3b8;
                    font-size: 0.9em;
                }
                .lz-dot {
                    color: #cbd5e1;
                    margin: 0 1px;
                }

                /* 重量 */
                .ranking-item > strong {
                    position: relative;
                    z-index: 2;
                    font-weight: 700 !important;
                    font-size: 1.3em !important;
                    min-width: 105px;
                    text-align: right;
                    color: #0f172a !important;
                }
                .ranking-item.rank-1 > strong {
                    font-size: 1.55em !important;
                    color: #c45a5d !important;
                    font-weight: 800 !important;
                }
                .ranking-item.rank-2 > strong {
                    font-size: 1.4em !important;
                    color: #b88930 !important;
                    font-weight: 800 !important;
                }
                .ranking-item.rank-3 > strong {
                    font-size: 1.35em !important;
                    color: #4e74b8 !important;
                    font-weight: 800 !important;
                }
                .ranking-item > strong .lz-unit {
                    font-size: 0.55em;
                    font-weight: 500;
                    margin-left: 2px;
                    opacity: 0.45;
                }

                .ranking-self-note {
                    background: rgba(203,213,225,0.5) !important;
                    color: #475569 !important;
                    padding: 1px 6px !important;
                    border-radius: 3px !important;
                    font-size: 0.7em !important;
                    margin-left: 4px;
                    font-weight: 500;
                    position: relative;
                    z-index: 2;
                }

                @keyframes lz-glow-pink {
                    0%, 100% { box-shadow: 0 0 12px 2px rgba(212,107,110,0.15); }
                    50% { box-shadow: 0 0 20px 4px rgba(212,107,110,0.25); }
                }
                @keyframes lz-glow-gold {
                    0%, 100% { box-shadow: 0 0 10px 2px rgba(196,154,60,0.12); }
                    50% { box-shadow: 0 0 18px 3px rgba(196,154,60,0.22); }
                }
                @keyframes lz-glow-blue {
                    0%, 100% { box-shadow: 0 0 9px 2px rgba(90,130,200,0.10); }
                    50% { box-shadow: 0 0 16px 3px rgba(90,130,200,0.20); }
                }
                @keyframes lz-glow-white {
                    0%, 100% { box-shadow: 0 0 6px 1px rgba(148,163,184,0.10); }
                    50% { box-shadow: 0 0 12px 2px rgba(148,163,184,0.20); }
                }
            `;
            document.head.appendChild(style);
        }

        function parseWeight(kg) {
            if (kg >= 5000) return { value: (kg / 1000).toFixed(2), unit: 'T' };
            return { value: kg.toFixed(2), unit: 'kg' };
        }

        function formatNumber(n) {
            const parts = n.split('.');
            return parseInt(parts[0]).toLocaleString() + (parts.length > 1 ? '.' + parts[1] : '');
        }

        function styleRankingList(list) {
            if (!list || list.getAttribute(STYLED_FLAG) === '1') return;
            list.setAttribute(STYLED_FLAG, '1');

            list.querySelectorAll('.ranking-item').forEach(item => {
                const detail = item.querySelector('.ranking-detail');
                if (detail) {
                    const parts = detail.textContent.trim().split('·');
                    if (parts.length === 2) {
                        detail.innerHTML =
                            '<span class="lz-strike-top"></span>' +
                            '<span class="lz-fish-name">' + parts[0].trim() + '</span>' +
                            '<span class="lz-dot"> · </span>' +
                            '<span class="lz-fish-size">' + parts[1].trim() + '</span>';
                    }
                }
                const strong = item.querySelector(':scope > strong');
                if (strong) {
                    const kg = parseFloat(strong.textContent.replace(/,/g, ''));
                    if (!isNaN(kg)) {
                        const w = parseWeight(kg);
                        strong.innerHTML = formatNumber(w.value) + '<span class="lz-unit">' + w.unit + '</span>';
                    }
                }
            });
        }

        function processAll() {
            injectStyles();
            document.querySelectorAll('.ranking-list').forEach(styleRankingList);
        }

        function init() {
            processAll();
            new MutationObserver(processAll).observe(document.body, { childList: true, subtree: true });
        }

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：鱼详情增加 kg/金币 和 kg/经验
function initFishValuePerKg() {
    (function() {
        'use strict';

        const INJECTED_FLAG = 'data-fvpkg-injected';

        function parseNumber(text) {
            if (!text) return NaN;
            const cleaned = text.replace(/[,，]/g, '').replace(/[^\d.]/g, '');
            return parseFloat(cleaned);
        }

        function tryInject(modal) {
            if (!modal || modal.getAttribute(INJECTED_FLAG) === '1') return;

            const stats = modal.querySelectorAll('.detail-stat');
            let weightKg = NaN;
            let price = NaN;
            let releaseExp = NaN;
            let priceStat = null;

            for (const s of stats) {
                const label = s.querySelector('.detail-stat-label');
                const value = s.querySelector('.detail-stat-value');
                if (!label || !value) continue;
                const labelText = label.textContent.trim();
                const valueText = value.textContent.trim();

                if (labelText === '重量') {
                    weightKg = parseNumber(valueText);
                } else if (labelText === '售出价值') {
                    price = parseNumber(valueText);
                    priceStat = s;
                } else if (labelText === '放生收益') {
                    releaseExp = parseNumber(valueText);
                }
            }

            // 需要至少两个数据点
            if (isNaN(weightKg) || weightKg <= 0) return;
            const hasPrice = !isNaN(price);
            const hasExp = !isNaN(releaseExp);
            if (!hasPrice && !hasExp) return;

            modal.setAttribute(INJECTED_FLAG, '1');

            // 插入位置：价格卡片后面（或重量卡片后面）
            const insertAfter = priceStat || stats[stats.length - 1];

            const card = document.createElement('div');
            card.className = 'detail-stat';
            card.style.cssText = 'border-left: 3px solid #38bdf8; padding-left: 8px; margin-top: 2px;';

            let html = '<span class="detail-stat-label">单位重量价值</span>';
            html += '<span class="detail-stat-value" style="display:flex; flex-wrap:wrap; gap:8px;">';

            if (hasPrice) {
                const perKg = price / weightKg;
                html += '<span title="售出价/重量">' +
                    '<span class="currency-display" style="display:inline-flex;align-items:center;gap:2px;">' +
                    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:#fbbf24"><path d="M13.744 17.736a6 6 0 1 1-7.48-7.48"/><path d="M15 6h1v4"/><path d="m6.134 14.768.866-.5 2 3.464"/><circle cx="16" cy="8" r="6"/></svg>' +
                    '<strong>' + perKg.toFixed(2) + '</strong></span>/kg' +
                    '</span>';
            }

            if (hasExp) {
                const perKg = releaseExp / weightKg;
                html += '<span title="放生经验/重量">' +
                    '<span style="display:inline-flex;align-items:center;gap:2px;color:#a78bfa;">' +
                    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>' +
                    '<strong>' + perKg.toFixed(2) + '</strong></span> EXP/kg' +
                    '</span>';
            }

            html += '</span>';
            card.innerHTML = html;

            if (insertAfter.nextSibling) {
                insertAfter.parentNode.insertBefore(card, insertAfter.nextSibling);
            } else {
                insertAfter.parentNode.appendChild(card);
            }
        }

        function processModals() {
            document.querySelectorAll('.modal-content').forEach(tryInject);
        }

        function init() {
            processModals();
            new MutationObserver(processModals).observe(document.body, { childList: true, subtree: true });
        }

        if (document.readyState === 'complete') init();
        else window.addEventListener('DOMContentLoaded', init);
    })();
}
// 功能：图鉴图片缓存
function initCatchPlate() {
    (function() {
        'use strict';

        const STYLED_FLAG = 'data-catch-plate-img';
        const CACHE_KEY = 'lz-fish-images';
        const MAX_CACHE = 500;
        const IS_DEX_PAGE = /\/dex(\?|#|$)/.test(location.href);

        // ========== 图鉴缓存部分 ==========
        let cache = {};
        try { cache = JSON.parse(GM_getValue(CACHE_KEY, '{}')); } catch (e) { cache = {}; }

        let scanTimer = null;
        let scannedCount = 0;

        function imgToBase64(img) {
            return new Promise(function(resolve) {
                if (img.loading === 'lazy') {
                    img.loading = 'eager';
                    const src = img.src;
                    img.src = '';
                    img.src = src;
                }

                function tryConvert() {
                    if (img.naturalWidth > 0) {
                        try {
                            const c = document.createElement('canvas');
                            let w = img.naturalWidth, h = img.naturalHeight;
                            if (w > 300 || h > 300) { const r = Math.min(300 / w, 300 / h); w = Math.round(w * r); h = Math.round(h * r); }
                            c.width = w; c.height = h;
                            c.getContext('2d').drawImage(img, 0, 0, w, h);
                            resolve(c.toDataURL('image/webp', 0.8));
                        } catch (e) { resolve(null); }
                        return;
                    }
                    setTimeout(tryConvert, 200);
                }

                if (img.complete && img.naturalWidth > 0) {
                    tryConvert();
                } else {
                    img.addEventListener('load', tryConvert, { once: true });
                    img.addEventListener('error', function() { resolve(null); }, { once: true });
                    setTimeout(function() { resolve(null); }, 5000);
                }
            });
        }

        async function scanAndCache() {
            const cards = document.querySelectorAll('.fish-card');
            let newCount = 0;
            const tasks = [];

            cards.forEach(function(card) {
                const nameEl = card.querySelector('.fish-name');
                if (!nameEl) return;
                const name = nameEl.textContent.trim();
                if (!name || cache[name]) return;
                const img = card.querySelector('.fish-card-photo');
                if (!img || !img.src) return;
                tasks.push(
                    imgToBase64(img).then(function(b64) {
                        if (b64) { cache[name] = b64; newCount++; }
                    })
                );
            });

            await Promise.allSettled(tasks);

            if (newCount > 0) {
                scannedCount += newCount;
                const keys = Object.keys(cache);
                if (keys.length > MAX_CACHE) {
                    keys.slice(0, keys.length - MAX_CACHE).forEach(function(k) { delete cache[k]; });
                }
                GM_setValue(CACHE_KEY, JSON.stringify(cache));
                console.log('[鱼图缓存] 本次新增 ' + newCount + ' 条，累计 ' + scannedCount + ' 条，缓存总数 ' + Object.keys(cache).length + ' 条');
            }
        }

        function scheduleScan() {
            clearTimeout(scanTimer);
            scanTimer = setTimeout(scanAndCache, 1500);
        }

        function getFishImage(name) {
            return cache[name] || '';
        }

        if (IS_DEX_PAGE) {
            console.log('[鱼图缓存] 检测到图鉴页面，启动扫描...');
            scheduleScan();
            new MutationObserver(scheduleScan).observe(document.body, { childList: true, subtree: true });
            window.addEventListener('scroll', scheduleScan, { passive: true });
        }

        // ========== 消息卡片美化部分 ==========
        function injectStyles() {
            if (document.getElementById('lz-catch-plate-img-styles')) return;
            const s = document.createElement('style');
            s.id = 'lz-catch-plate-img-styles';
            s.textContent = `
                .message-card--catch{position:relative;border-radius:40px!important;overflow:hidden!important;padding:16px 20px!important;background:#fff!important;border:none!important;transition:transform .15s ease,box-shadow .15s ease}
                .message-card--catch:hover{transform:translateY(-1px)}
                .message-card--catch.lz-ct-gray{background:linear-gradient(135deg,#e2e8f0 0%,#f8fafc 30%,#fff 60%,#fff 100%)!important}
                .message-card--catch.lz-ct-gray:hover{box-shadow:0 4px 12px rgba(148,163,184,.15)}
                .message-card--catch.lz-ct-shrimp{background:linear-gradient(135deg,#e2e8f0 0%,#f8fafc 30%,#fff 60%,#fff 100%)!important;border:2px solid #fbbf24!important;box-shadow:0 0 8px rgba(251,191,36,.3)}
                .message-card--catch.lz-ct-shrimp:hover{box-shadow:0 4px 14px rgba(251,191,36,.25)}
                .message-card--catch.lz-ct-green{background:linear-gradient(135deg,#4ade80 0%,#bbf7d0 25%,#f0fdf4 50%,#fff 100%)!important}
                .message-card--catch.lz-ct-green:hover{box-shadow:0 4px 14px rgba(74,222,128,.18)}
                .message-card--catch.lz-ct-blue{background:linear-gradient(135deg,#60a5fa 0%,#bfdbfe 25%,#eff6ff 50%,#fff 100%)!important}
                .message-card--catch.lz-ct-blue:hover{box-shadow:0 4px 14px rgba(96,165,250,.18)}
                .message-card--catch.lz-ct-yellow{background:linear-gradient(135deg,#fbbf24 0%,#fde68a 25%,#fffbeb 50%,#fff 100%)!important}
                .message-card--catch.lz-ct-yellow:hover{box-shadow:0 4px 14px rgba(251,191,36,.18)}
                .message-card--catch.lz-ct-legendary{background:linear-gradient(135deg,#ef4444 0%,#fca5a5 15%,#fde68a 35%,#fffbeb 55%,#fff 100%)!important;animation:lz-legendary-bg 2.5s ease-in-out infinite}
                .message-card--catch.lz-ct-legendary:hover{box-shadow:0 4px 18px rgba(239,68,68,.25)}
                @keyframes lz-legendary-bg{0%,100%{background:linear-gradient(135deg,#ef4444 0%,#fca5a5 15%,#fde68a 35%,#fffbeb 55%,#fff 100%)!important}50%{background:linear-gradient(135deg,#dc2626 0%,#f87171 15%,#fbbf24 35%,#fef3c7 55%,#fff 100%)!important}}
                
                /* ========== 恢复评分条显示 ========== */
                .catch-rating-bar {
                    display: block !important; /* 重新显示评分条 */
                    height: 6px;
                    border-radius: 3px;
                    margin-top: 8px;
                    background: rgba(0,0,0,0.06);
                    overflow: hidden;
                    position: relative;
                }
                
                .catch-rating-bar .catch-rating-fill {
                    height: 100%;
                    border-radius: 3px;
                    transition: width 0.3s ease;
                }
                
                /* 不同品质的评分条颜色 */
                .lz-ct-shrimp .catch-rating-bar .catch-rating-fill {
                    background: linear-gradient(90deg, #fbbf24, #f59e0b);
                }
                .lz-ct-gray .catch-rating-bar .catch-rating-fill {
                    background: linear-gradient(90deg, #94a3b8, #64748b);
                }
                .lz-ct-green .catch-rating-bar .catch-rating-fill {
                    background: linear-gradient(90deg, #4ade80, #22c55e);
                }
                .lz-ct-blue .catch-rating-bar .catch-rating-fill {
                    background: linear-gradient(90deg, #60a5fa, #3b82f6);
                }
                .lz-ct-yellow .catch-rating-bar .catch-rating-fill {
                    background: linear-gradient(90deg, #fbbf24, #f59e0b);
                }
                .lz-ct-legendary .catch-rating-bar .catch-rating-fill {
                    background: linear-gradient(90deg, #ef4444, #dc2626, #fbbf24);
                    animation: lz-legendary-bar 2s ease-in-out infinite;
                }
                
                @keyframes lz-legendary-bar {
                    0%, 100% { background: linear-gradient(90deg, #ef4444, #dc2626, #fbbf24); }
                    50% { background: linear-gradient(90deg, #fbbf24, #ef4444, #dc2626); }
                }
                
                .lz-ct-inner{display:flex;align-items:stretch;gap:0;position:relative}
                .lz-ct-left{flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center}
                .lz-ct-right{flex-shrink:0;width:120px;display:flex;align-items:center;justify-content:center;overflow:visible}
                .lz-ct-fish-img{width:120px;height:auto;max-height:100%;object-fit:contain;object-position:right center;opacity:0.45;filter:drop-shadow(0 0 8px rgba(255,255,255,.6));pointer-events:none;mix-blend-mode:multiply}
                .message-card--catch.lz-ct-gray .lz-ct-fish-img{opacity:0.4}
                .message-card--catch.lz-ct-shrimp .lz-ct-fish-img{opacity:0.4}
                .message-card--catch.lz-ct-green .lz-ct-fish-img{opacity:0.4}
                .message-card--catch.lz-ct-blue .lz-ct-fish-img{opacity:0.4}
                .message-card--catch.lz-ct-yellow .lz-ct-fish-img{opacity:0.4}
                .message-card--catch.lz-ct-legendary .lz-ct-fish-img{opacity:0.35}
                .lz-ct-tag{display:inline-block;font-size:.7em;font-weight:600;padding:3px 8px;border-radius:10px;vertical-align:middle;letter-spacing:.3px}
                .lz-ct-tag-gray{background:#e2e8f0;color:#475569}
                .lz-ct-tag-shrimp{background:#64748b;color:#f1f5f9}
                .lz-ct-tag-green{background:#166534;color:#dcfce7}
                .lz-ct-tag-blue{background:#1e40af;color:#dbeafe}
                .lz-ct-tag-yellow{background:#92400e;color:#fef3c7}
                .lz-ct-tag-red{background:#991b1b;color:#fee2e2}
                .lz-ct-fish-title{font-size:1.1em;font-weight:700;color:#0f172a;display:block;margin-bottom:2px;letter-spacing:.3px}
                .lz-ct-info-row{font-size:.8em;color:#64748b;display:flex;align-items:center;gap:6px;flex-wrap:wrap}
                .lz-ct-spec{font-size:.85em;color:#64748b}
                
                /* 百分比显示 */
                .lz-ct-percentage {
                    font-size: 0.85em;
                    font-weight: 700;
                    margin-top: 4px;
                    display: inline-block;
                    padding: 2px 6px;
                    border-radius: 4px;
                    background: rgba(0,0,0,0.04);
                }
            `;
            document.head.appendChild(s);
        }

        function getRatingInfo(text) {
            const parts = text.split('·');
            if (parts.length < 2) return null;
            const name = parts[0].trim();
            const m = parts[1].match(/([\d.]+)%\s+(.+)/);
            if (!m) return null;
            const score = parseFloat(m[1]);
            const rating = m[2].trim();
            const rest = parts.slice(2).join('·').trim();

            if (score < 2) return { name, score, label:'经验宝宝', rest, cardClass:'lz-ct-shrimp', tagClass:'lz-ct-tag-shrimp' };
            switch (rating) {
                case '不达标': return { name, score, label:'不达标', rest, cardClass:'lz-ct-gray', tagClass:'lz-ct-tag-gray' };
                case '达标': return { name, score, label:'达标', rest, cardClass:'lz-ct-green', tagClass:'lz-ct-tag-green' };
                case '稀有': return { name, score, label:'稀有', rest, cardClass:'lz-ct-blue', tagClass:'lz-ct-tag-blue' };
                case '罕见': return { name, score, label:'罕见', rest, cardClass:'lz-ct-yellow', tagClass:'lz-ct-tag-yellow' };
                case '传说': return { name, score, label:'传说', rest, cardClass:'lz-ct-legendary', tagClass:'lz-ct-tag-red' };
                default: return { name, score, label:rating, rest, cardClass:'lz-ct-green', tagClass:'lz-ct-tag-green' };
            }
        }

        function processCards() {
            injectStyles();
            document.querySelectorAll('.message-card--catch').forEach(function(card) {
                if (card.getAttribute(STYLED_FLAG) === '1') return;
                const detail = card.querySelector('.text-sm.text-muted.mt-sm');
                if (!detail) return;
                const info = getRatingInfo(detail.textContent);
                if (!info) return;

                card.setAttribute(STYLED_FLAG, '1');
                card.classList.add(info.cardClass);

                const titleEl = card.querySelector('.message-title');
                if (titleEl) {
                    titleEl.innerHTML = '<span class="lz-ct-fish-title">' + info.name + '</span>';
                }

                // 重构detail内容：标签 + 规格 + 百分比
                let detailHTML = '<div class="lz-ct-info-row">';
                detailHTML += '<span class="lz-ct-tag ' + info.tagClass + '">' + info.label + '</span>';
                if (info.rest) {
                    detailHTML += '<span class="lz-ct-spec">' + info.rest + '</span>';
                }
                detailHTML += '</div>';
                
                // 添加百分比显示
                detailHTML += '<span class="lz-ct-percentage">' + info.score + '%</span>';
                
                detail.innerHTML = detailHTML;

                // 处理评分条（如果存在）
                const ratingBar = card.querySelector('.catch-rating-bar');
                const ratingFill = card.querySelector('.catch-rating-bar .catch-rating-fill');
                if (ratingFill) {
                    ratingFill.style.width = info.score + '%';
                }
                
                // 如果没有评分条但有评分数据，创建评分条
                if (!ratingBar && info.score !== undefined) {
                    const bar = document.createElement('div');
                    bar.className = 'catch-rating-bar';
                    const fill = document.createElement('div');
                    fill.className = 'catch-rating-fill';
                    fill.style.width = info.score + '%';
                    bar.appendChild(fill);
                    
                    // 添加到detail后面或title下面
                    const insertAfter = detail.nextElementSibling || detail;
                    insertAfter.parentNode.insertBefore(bar, insertAfter.nextSibling);
                }

                const imgSrc = getFishImage(info.name);
                const flex = card.querySelector('.flex.items-start');
                if (imgSrc && flex && !flex.querySelector('.lz-ct-fish-img')) {
                    const left = document.createElement('div'); left.className = 'lz-ct-left';
                    while (flex.firstChild) left.appendChild(flex.firstChild);
                    const right = document.createElement('div'); right.className = 'lz-ct-right';
                    const img = document.createElement('img'); img.className = 'lz-ct-fish-img'; img.src = imgSrc; img.alt = info.name;
                    right.appendChild(img);
                    const inner = document.createElement('div'); inner.className = 'lz-ct-inner';
                    inner.appendChild(left); inner.appendChild(right);
                    flex.appendChild(inner);
                }
            });
        }

        processCards();
        new MutationObserver(processCards).observe(document.body, { childList: true, subtree: true });
    })();
}
// 功能：口数趋势图 v9 - 固定总时长2小时版
// 注册名：intervalTrendChart
// ============================================================
function initIntervalTrendChart() {
    (function() {
        'use strict';

        const CHART_PANEL_ID = 'interval-trend-chart-panel';
        const INIT_DELAY = 3000;
        const UPDATE_INTERVAL = 20000;
        const CHART_HEIGHT = 140;
        const MAX_LAYERS = 4;
        const MAX_POINTS = 150;
        const TOTAL_HOURS = 2;  // 固定总时长

        let timer = null;

        function parseCatchData() {
            var cards = document.querySelectorAll('.message-card--catch');
            var data = [];
            var limit = Math.min(cards.length, 200);
            for (var i = 0; i < limit; i++) {
                var card = cards[i];
                var intervalEl = card.querySelector('.catch-interval');
                var timeEl = card.querySelector('.text-xs.text-muted');
                if (!intervalEl || !timeEl) continue;
                var intMatch = intervalEl.textContent.match(/(\d+)/);
                var timeMatch = timeEl.textContent.match(/(\d{4}\/\d{2}\/\d{2}\s+\d{2}:\d{2}:\d{2})/);
                if (!intMatch || !timeMatch) continue;
                data.push({
                    minutes: parseInt(intMatch[1]),
                    datetime: new Date(timeMatch[1])
                });
            }
            data.sort(function(a, b) { return a.datetime - b.datetime; });
            return data;
        }

        function buildChart(allData, width) {
            if (allData.length < 2) return null;

            var now = Date.now();
            var twoHoursAgo = now - TOTAL_HOURS * 60 * 60 * 1000;

            // 筛选最近2小时的数据
            var data = [];
            for (var i = 0; i < allData.length; i++) {
                if (allData[i].datetime.getTime() >= twoHoursAgo) {
                    data.push(allData[i]);
                }
            }
            if (data.length < 2) return null;

            // 固定时间轴：从2小时前到现在
            var xMin = twoHoursAgo;
            var xMax = now;

            var allMinutes = [];
            for (var j = 0; j < data.length; j++) {
                allMinutes.push(data[j].minutes);
            }

            var globalMax = 1;
            for (var k = 0; k < allMinutes.length; k++) {
                if (allMinutes[k] > globalMax) globalMax = allMinutes[k];
            }
            var roundedMax = Math.ceil(globalMax / 10) * 10 || 10;

            var p = { top: 10, right: 34, bottom: 25, left: 4 };
            var cw = width - p.left - p.right;
            var ch = CHART_HEIGHT - p.top - p.bottom;

            function xPos(ts) { return p.left + ((ts - xMin) / (xMax - xMin || 1)) * cw; }
            function yPos(val) { return p.top + ch - (val / roundedMax) * ch; }

            // 按1小时分组（在2小时内）
            var groups = [];
            var latest = new Date(now);
            var windowEnd = new Date(latest);
            windowEnd.setMinutes(0, 0, 0);
            windowEnd.setHours(windowEnd.getHours() + 1);

            var currentEnd = new Date(windowEnd);
            var maxIter = 5;
            while (maxIter-- > 0 && groups.length < MAX_LAYERS) {
                var currentStart = new Date(currentEnd.getTime() - 60 * 60 * 1000);
                var slice = [];
                for (var s = data.length - 1; s >= 0; s--) {
                    if (data[s].datetime >= currentStart && data[s].datetime < currentEnd) {
                        slice.unshift(data[s]);
                    }
                    if (data[s].datetime < currentStart) break;
                }
                if (slice.length > 0) groups.push(slice);
                currentEnd = new Date(currentStart);
                if (currentStart <= xMin) break;
            }

            var layerColors = [
                { stroke: '#38bdf8', area: 'rgba(56,189,248,0.14)' },
                { stroke: '#818cf8', area: 'rgba(129,140,248,0.09)' },
                { stroke: '#a78bfa', area: 'rgba(167,139,250,0.05)' },
                { stroke: '#94a3b8', area: 'rgba(148,163,184,0.03)' },
            ];

            var parts = [];

            // 标题
            var totalCount = data.length;
            var totalMin = 0;
            for (var t = 0; t < data.length; t++) totalMin += data[t].minutes;
            var avg = Math.round(totalMin / totalCount);
            parts.push('<text x="' + p.left + '" y="8" fill="#94a3b8" font-size="9" font-weight="500">近2h · ' + totalCount + '条 · 均' + avg + '分</text>');

            // 网格
            var yTicks = [0, Math.round(roundedMax / 3), Math.round(roundedMax * 2 / 3), roundedMax];
            for (var ti = 0; ti < yTicks.length; ti++) {
                var v = yTicks[ti];
                var y = yPos(v).toFixed(2);
                parts.push('<line x1="' + p.left + '" y1="' + y + '" x2="' + (p.left + cw).toFixed(2) + '" y2="' + y + '" stroke="#1e293b" stroke-width="0.5" stroke-dasharray="4,4"/>');
            }

            // 填充区域
            for (var gi = groups.length - 1; gi >= 0; gi--) {
                var g = groups[gi];
                var li = groups.length - 1 - gi;
                var color = layerColors[Math.min(li, layerColors.length - 1)];

                if (g.length < 2) continue;

                var areaPathParts = [];
                var areaStartX = xPos(g[0].datetime.getTime()).toFixed(2);
                var areaEndX = xPos(g[g.length - 1].datetime.getTime()).toFixed(2);
                var bottomY = (p.top + ch).toFixed(2);

                areaPathParts.push('M' + areaStartX + ',' + bottomY);
                for (var ai = 0; ai < g.length; ai++) {
                    var ax = xPos(g[ai].datetime.getTime()).toFixed(2);
                    var ay = yPos(g[ai].minutes).toFixed(2);
                    areaPathParts.push('L' + ax + ',' + ay);
                }
                areaPathParts.push('L' + areaEndX + ',' + bottomY + 'Z');
                var areaPath = areaPathParts.join('');
                parts.push('<path d="' + areaPath + '" fill="' + color.area + '"/>');
            }

            // 曲线
            for (var gi2 = groups.length - 1; gi2 >= 0; gi2--) {
                var g2 = groups[gi2];
                var li2 = groups.length - 1 - gi2;
                var color2 = layerColors[Math.min(li2, layerColors.length - 1)];
                var opacity = li2 === 0 ? 1 : 0.5;
                var lineW = li2 === 0 ? 2 : 1.2;

                if (g2.length < 2) continue;

                var pathParts = [];
                for (var pi = 0; pi < g2.length; pi++) {
                    var sx = xPos(g2[pi].datetime.getTime()).toFixed(2);
                    var sy = yPos(g2[pi].minutes).toFixed(2);
                    if (pi === 0) {
                        pathParts.push('M' + sx + ',' + sy);
                    } else {
                        var prev = g2[pi - 1];
                        var cpx = ((xPos(prev.datetime.getTime()) + xPos(g2[pi].datetime.getTime())) / 2).toFixed(2);
                        pathParts.push('C' + cpx + ',' + yPos(prev.minutes).toFixed(2) + ' ' +
                                       cpx + ',' + sy + ' ' + sx + ',' + sy);
                    }
                }
                var pathD = pathParts.join('');
                parts.push('<path d="' + pathD + '" fill="none" stroke="' + color2.stroke + '" stroke-width="' + lineW + '" stroke-linecap="round" stroke-linejoin="round" opacity="' + opacity + '"/>');
            }

            // 最新层数据点
            if (groups.length > 0) {
                var latestG = groups[0];
                var dotsToShow = latestG;
                if (dotsToShow.length > MAX_POINTS) {
                    var step = Math.ceil(dotsToShow.length / MAX_POINTS);
                    var sampled = [];
                    for (var sm = 0; sm < dotsToShow.length; sm += step) sampled.push(dotsToShow[sm]);
                    if (sampled[sampled.length - 1] !== dotsToShow[dotsToShow.length - 1]) sampled.push(dotsToShow[dotsToShow.length - 1]);
                    dotsToShow = sampled;
                }
                var dotColor = layerColors[0].stroke;
                for (var dp = 0; dp < dotsToShow.length; dp++) {
                    var dx = xPos(dotsToShow[dp].datetime.getTime()).toFixed(2);
                    var dy = yPos(dotsToShow[dp].minutes).toFixed(2);
                    parts.push('<circle cx="' + dx + '" cy="' + dy + '" r="2" fill="#0f172a" stroke="' + dotColor + '" stroke-width="1.2"/>');
                }
            }

            // Y轴标签
            for (var ti2 = 0; ti2 < yTicks.length; ti2++) {
                var v2 = yTicks[ti2];
                var y2 = yPos(v2).toFixed(2);
                parts.push('<text x="' + (p.left + cw + 6).toFixed(2) + '" y="' + y2 + '" fill="#64748b" font-size="9" dominant-baseline="middle">' + v2 + 'm</text>');
            }

            // X轴标签（固定5个）
            for (var xt = 0; xt <= 4; xt++) {
                var ts = xMin + ((xMax - xMin) / 4) * xt;
                var d = new Date(ts);
                var label = ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2);
                var x = xPos(ts).toFixed(2);
                parts.push('<text x="' + x + '" y="' + (p.top + ch + 16).toFixed(2) + '" fill="#64748b" font-size="8.5" text-anchor="middle">' + label + '</text>');
            }

            return '<svg width="' + width + '" height="' + CHART_HEIGHT + '" viewBox="0 0 ' + width + ' ' + CHART_HEIGHT + '" style="display:block;font-family:system-ui,sans-serif;">' +
                parts.join('') + '</svg>';
        }

        function renderPanel() {
            var summaryPanel = document.getElementById('catch-summary-panel-v12');
            if (!summaryPanel) return;

            var allData = parseCatchData();
            if (allData.length < 2) return;

            var w = Math.max(280, Math.min(summaryPanel.clientWidth - 28, 600));
            var chart = buildChart(allData, w);
            if (!chart) return;

            var old = document.getElementById(CHART_PANEL_ID);
            if (old) old.remove();

            var panel = document.createElement('div');
            panel.id = CHART_PANEL_ID;
            panel.className = 'card mt-sm';
            panel.style.cssText = 'padding:12px 14px;';
            panel.innerHTML = chart;

            summaryPanel.parentNode.insertBefore(panel, summaryPanel.nextSibling);
        }

        function init() {
            setTimeout(function() {
                renderPanel();
                timer = setInterval(renderPanel, UPDATE_INTERVAL);
            }, INIT_DELAY);
        }

        window.addEventListener('beforeunload', function() {
            if (timer) { clearInterval(timer); timer = null; }
        });

        if (document.readyState === 'complete') {
            init();
        } else {
            window.addEventListener('load', init);
        }
    })();
}
// ============================================================
// 功能：船上成员排序 v12 - 即时渲染版
// 注册名：boatMemberSort
// ============================================================
function initBoatMemberSort() {
    (function() {
        'use strict';

        const STATUS_MAP = {
            'REELING': '上鱼',
            'FIGHTING': '搏斗',
            'FISHING': '守钓',
            'IDLE': '空闲',
            'AT_SPOT': '停杆',
            'BITE_WINDOW': '鱼讯'
        };

        const STATUS_COLOR = {
            'REELING': '#f59e0b',
            'FIGHTING': '#ef4444',
            'FISHING': '#22c55e',
            'IDLE': '#6b7280',
            'AT_SPOT': '#3b82f6',
            'BITE_WINDOW': '#a855f7'
        };

        let currentSort = 'weight';
        let isProcessing = false;
        let styleInjected = false;

        const STYLE_ID = 'boat-rank-styles';
        const BAR_CLASS = 'member-sort-bar';
        const BADGE_CLASS = 'rank-badge';
        const TAG_CLASS = 'sort-value-tag';

        function ensureStyles() {
            if (styleInjected || document.getElementById(STYLE_ID)) {
                styleInjected = true;
                return;
            }
            var style = document.createElement('style');
            style.id = STYLE_ID;
            style.textContent = `
                .rank-1-bg {
                    background:
                        radial-gradient(1px 1px at 5% 8%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(2px 2px at 12% 22%, rgba(255,255,255,0.95), transparent),
                        radial-gradient(1px 1px at 18% 5%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1.5px 1.5px at 25% 18%, rgba(255,215,0,0.9), transparent),
                        radial-gradient(1px 1px at 32% 10%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2.5px 2.5px at 38% 28%, rgba(255,255,255,1), transparent),
                        radial-gradient(1px 1px at 45% 8%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 52% 20%, rgba(255,240,220,0.9), transparent),
                        radial-gradient(1px 1px at 58% 12%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(2px 2px at 65% 25%, rgba(255,255,255,0.95), transparent),
                        radial-gradient(1px 1px at 72% 8%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1.5px 1.5px at 78% 22%, rgba(255,215,0,0.9), transparent),
                        radial-gradient(1px 1px at 85% 10%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2.5px 2.5px at 92% 28%, rgba(255,255,255,1), transparent),
                        radial-gradient(1px 1px at 8% 38%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 15% 48%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 22% 35%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2px 2px at 30% 42%, rgba(255,240,220,0.95), transparent),
                        radial-gradient(1px 1px at 38% 50%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1.5px 1.5px at 45% 38%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 52% 48%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2px 2px at 60% 35%, rgba(255,215,0,0.95), transparent),
                        radial-gradient(1px 1px at 68% 45%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 75% 42%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 82% 50%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2px 2px at 88% 38%, rgba(255,255,255,0.95), transparent),
                        radial-gradient(1px 1px at 95% 48%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1px 1px at 5% 60%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(1.5px 1.5px at 12% 72%, rgba(255,215,0,0.9), transparent),
                        radial-gradient(1px 1px at 20% 58%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(2px 2px at 28% 68%, rgba(255,255,255,0.95), transparent),
                        radial-gradient(1px 1px at 35% 55%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(1.5px 1.5px at 42% 65%, rgba(255,240,220,0.9), transparent),
                        radial-gradient(1px 1px at 50% 60%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(2px 2px at 58% 72%, rgba(255,255,255,0.95), transparent),
                        radial-gradient(1px 1px at 65% 58%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(1.5px 1.5px at 72% 68%, rgba(255,215,0,0.9), transparent),
                        radial-gradient(1px 1px at 78% 55%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(2px 2px at 85% 65%, rgba(255,255,255,0.95), transparent),
                        radial-gradient(1px 1px at 92% 60%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(1px 1px at 10% 82%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1.5px 1.5px at 18% 92%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 26% 80%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2px 2px at 34% 88%, rgba(255,240,220,0.95), transparent),
                        radial-gradient(1px 1px at 42% 78%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 50% 85%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 58% 82%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(2px 2px at 66% 90%, rgba(255,215,0,0.95), transparent),
                        radial-gradient(1px 1px at 74% 78%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1.5px 1.5px at 82% 88%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 88% 82%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(2px 2px at 95% 90%, rgba(255,255,255,0.95), transparent),
                        linear-gradient(135deg, #050518 0%, #0a0a25 30%, #08081e 60%, #0b0b28 100%);
                    border: 1px solid rgba(255,215,0,0.25);
                    box-shadow: 0 0 20px rgba(255,215,0,0.12);
                    border-radius: 8px;
                }
                .rank-2-bg {
                    background:
                        radial-gradient(1px 1px at 8% 15%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 22% 28%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(1px 1px at 35% 12%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(2px 2px at 48% 25%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 58% 18%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 70% 30%, rgba(255,240,220,0.85), transparent),
                        radial-gradient(1px 1px at 82% 15%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(2px 2px at 92% 28%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 15% 45%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 30% 52%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(1px 1px at 45% 40%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(2px 2px at 58% 48%, rgba(255,215,0,0.9), transparent),
                        radial-gradient(1px 1px at 68% 55%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 80% 42%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(1px 1px at 90% 50%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(1px 1px at 10% 65%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 25% 75%, rgba(255,240,220,0.85), transparent),
                        radial-gradient(1px 1px at 40% 62%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(2px 2px at 55% 70%, rgba(255,255,255,0.9), transparent),
                        radial-gradient(1px 1px at 65% 78%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 78% 65%, rgba(255,255,255,0.85), transparent),
                        radial-gradient(1px 1px at 88% 72%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(1px 1px at 18% 88%, rgba(255,255,255,0.7), transparent),
                        radial-gradient(1.5px 1.5px at 35% 85%, rgba(255,215,0,0.85), transparent),
                        radial-gradient(1px 1px at 50% 92%, rgba(255,255,255,0.65), transparent),
                        radial-gradient(2px 2px at 72% 88%, rgba(255,255,255,0.9), transparent),
                        linear-gradient(135deg, #06061a 0%, #0c0c28 30%, #090920 60%, #0b0b26 100%);
                    border: 1px solid rgba(192,192,192,0.2);
                    box-shadow: 0 0 18px rgba(192,192,192,0.08);
                    border-radius: 8px;
                }
                .rank-3-bg {
                    background:
                        radial-gradient(1px 1px at 12% 20%, rgba(255,255,255,0.6), transparent),
                        radial-gradient(1.5px 1.5px at 35% 35%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1px 1px at 55% 18%, rgba(255,255,255,0.6), transparent),
                        radial-gradient(2px 2px at 75% 30%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(1px 1px at 20% 55%, rgba(255,255,255,0.6), transparent),
                        radial-gradient(1.5px 1.5px at 45% 62%, rgba(255,255,255,0.75), transparent),
                        radial-gradient(1px 1px at 65% 50%, rgba(255,255,255,0.6), transparent),
                        radial-gradient(2px 2px at 85% 65%, rgba(255,255,255,0.8), transparent),
                        radial-gradient(1px 1px at 15% 82%, rgba(255,255,255,0.6), transparent),
                        radial-gradient(1.5px 1.5px at 50% 88%, rgba(255,255,255,0.75), transparent),
                        linear-gradient(135deg, #07071a 0%, #0d0d25 30%, #0a0a1e 60%, #0c0c24 100%);
                    border: 1px solid rgba(205,127,50,0.18);
                    box-shadow: 0 0 16px rgba(205,127,50,0.06);
                    border-radius: 8px;
                }
                .rank-1-bg .item-name { color: #f1f5f9 !important; font-weight: 700; }
                .rank-2-bg .item-name { color: #e2e8f0 !important; font-weight: 700; }
                .rank-3-bg .item-name { color: #cbd5e1 !important; font-weight: 700; }
                .rank-1-bg .item-stat, .rank-2-bg .item-stat, .rank-3-bg .item-stat { color: #94a3b8 !important; }
                .rank-1-bg .inline-meta, .rank-2-bg .inline-meta, .rank-3-bg .inline-meta { font-size: 13px !important; font-weight: 600 !important; }
                .rank-1-bg .sort-value-tag { color: #ffd700 !important; font-weight: 600; }
                .rank-2-bg .sort-value-tag { color: #c0c0c0 !important; font-weight: 600; }
                .rank-3-bg .sort-value-tag { color: #cd7f32 !important; font-weight: 600; }
            `;
            document.head.appendChild(style);
            styleInjected = true;
        }

        function translateStatus(text) {
            return STATUS_MAP[text] || text;
        }

        function getStatusColor(text) {
            return STATUS_COLOR[text] || '#94a3b8';
        }

        function parseWeight(text) {
            if (!text) return 0;
            var kg = text.match(/([\d.]+)\s*kg/);
            if (kg) return parseFloat(kg[1]) * 1000;
            var g = text.match(/([\d.]+)\s*g/);
            if (g) return parseFloat(g[1]);
            return 0;
        }

        function parseCount(text) {
            if (!text) return 0;
            var m = text.match(/(\d+)\s*条/);
            return m ? parseInt(m[1]) : 0;
        }

        function getMemberData(card) {
            var n = card.querySelector('.item-name');
            var name = n ? n.textContent.trim() : '';
            var s = card.querySelector('.inline-meta');
            var raw = s ? s.textContent.trim() : '';
            var stats = card.querySelectorAll('.item-stat');
            var w = 0, c = 0, mw = 0;
            for (var i = 0; i < stats.length; i++) {
                var t = stats[i].textContent.trim();
                if (t.indexOf('总重') !== -1) w = parseWeight(t);
                else if (t.indexOf('鱼获') !== -1) c = parseCount(t);
                else if (t.indexOf('最大') !== -1) mw = parseWeight(t);
            }
            return { card: card, name: name, rawStatus: raw, weight: w, count: c, maxWeight: mw };
        }

        function sortMembers(list) {
            if (currentSort === 'weight') list.sort(function(a, b) { return b.weight - a.weight; });
            else if (currentSort === 'count') list.sort(function(a, b) { return b.count - a.count; });
            else list.sort(function(a, b) { return b.maxWeight - a.maxWeight; });
        }

        function formatWeight(g) {
            if (g >= 1000) return (g / 1000).toFixed(2) + 'kg';
            return g + 'g';
        }

        function getRankBadge(rank) {
            if (rank === 0) return { text: 'No.1', color: '#ffd700', bg: 'rgba(255,215,0,0.15)' };
            if (rank === 1) return { text: 'No.2', color: '#c0c0c0', bg: 'rgba(192,192,192,0.12)' };
            if (rank === 2) return { text: 'No.3', color: '#cd7f32', bg: 'rgba(205,127,50,0.12)' };
            return null;
        }

        function getSortValueText(member) {
            if (currentSort === 'weight') return formatWeight(member.weight);
            if (currentSort === 'count') return member.count + '条';
            return formatWeight(member.maxWeight);
        }

        function processCards(container) {
            if (isProcessing) return;
            isProcessing = true;

            var cards = container.querySelectorAll(':scope > .item-card');
            if (cards.length < 2) { isProcessing = false; return; }

            var members = [];
            for (var i = 0; i < cards.length; i++) {
                members.push(getMemberData(cards[i]));
            }

            sortMembers(members);

            // 批量更新 DOM
            for (var k = 0; k < members.length; k++) {
                var card = members[k].card;

                // 排名样式
                card.classList.remove('rank-1-bg', 'rank-2-bg', 'rank-3-bg');
                if (k === 0) card.classList.add('rank-1-bg');
                else if (k === 1) card.classList.add('rank-2-bg');
                else if (k === 2) card.classList.add('rank-3-bg');

                // 徽章
                var oldBadge = card.querySelector('.' + BADGE_CLASS);
                if (oldBadge) oldBadge.remove();
                if (k < 3) {
                    var badge = getRankBadge(k);
                    var badgeEl = document.createElement('span');
                    badgeEl.className = BADGE_CLASS;
                    badgeEl.textContent = badge.text;
                    badgeEl.style.cssText = 'font-size:10px;font-weight:700;padding:1px 6px;border-radius:3px;margin-right:6px;color:' + badge.color + ';background:' + badge.bg + ';';
                    var n1 = card.querySelector('.item-name');
                    if (n1) n1.insertBefore(badgeEl, n1.firstChild);
                }

                // 状态
                var statusEl = card.querySelector('.inline-meta');
                if (statusEl) {
                    var translated = translateStatus(members[k].rawStatus);
                    if (statusEl.textContent !== translated) statusEl.textContent = translated;
                    statusEl.style.color = getStatusColor(members[k].rawStatus);
                }

                // 排序值
                var oldTag = card.querySelector('.' + TAG_CLASS);
                if (oldTag) oldTag.remove();
                var tag = document.createElement('span');
                tag.className = TAG_CLASS;
                tag.style.cssText = 'font-size:10px;margin-left:6px;';
                tag.textContent = getSortValueText(members[k]);
                var n2 = card.querySelector('.item-name');
                if (n2) n2.appendChild(tag);
            }

            // 用 fragment 一次性重排
            var frag = document.createDocumentFragment();
            for (var j = 0; j < members.length; j++) {
                frag.appendChild(members[j].card);
            }
            container.appendChild(frag);

            isProcessing = false;
        }

        function updateButtons() {
            var bar = document.querySelector('.' + BAR_CLASS);
            if (!bar) return;
            var btns = bar.querySelectorAll('.member-sort-btn');
            for (var i = 0; i < btns.length; i++) {
                var key = btns[i].getAttribute('data-sort');
                var active = key === currentSort;
                btns[i].style.borderColor = active ? '#38bdf8' : '#334155';
                btns[i].style.background = active ? 'rgba(56,189,248,0.15)' : 'rgba(30,41,59,0.6)';
                btns[i].style.color = active ? '#38bdf8' : '#94a3b8';
                btns[i].style.fontWeight = active ? '600' : '400';
            }
        }

        function createButtons(container) {
            var parent = container.parentNode;
            if (parent.querySelector('.' + BAR_CLASS)) return;

            var bar = document.createElement('div');
            bar.className = BAR_CLASS;
            bar.style.cssText = 'display:flex;gap:6px;margin-bottom:10px;align-items:center;';

            var opts = [
                { key: 'weight', label: '总重' },
                { key: 'count', label: '数量' },
                { key: 'maxWeight', label: '最大' }
            ];

            for (var i = 0; i < opts.length; i++) {
                var btn = document.createElement('button');
                btn.className = 'member-sort-btn';
                btn.textContent = opts[i].label;
                btn.setAttribute('data-sort', opts[i].key);
                btn.style.cssText = 'padding:5px 14px;border:1px solid #334155;border-radius:6px;background:rgba(30,41,59,0.6);color:#94a3b8;font-size:12px;cursor:pointer;transition:all 0.15s;font-weight:400;';
                btn.addEventListener('click', function(e) {
                    currentSort = e.target.getAttribute('data-sort');
                    var list = document.querySelector('.card-list.mt-md.mb-sm');
                    if (list) processCards(list);
                    updateButtons();
                });
                bar.appendChild(btn);
            }

            parent.insertBefore(bar, container);
            updateButtons();
        }

        function run() {
            ensureStyles();
            var list = document.querySelector('.card-list.mt-md.mb-sm');
            if (!list) return;
            if (list.querySelectorAll(':scope > .item-card').length < 2) return;
            createButtons(list);
            processCards(list);
        }

        // 用 requestAnimationFrame 确保 DOM 已渲染
        function scheduleRun() {
            requestAnimationFrame(function() {
                requestAnimationFrame(run);
            });
        }

        // 初始化：立即执行 + 监听
        if (document.readyState === 'complete') {
            scheduleRun();
        } else {
            window.addEventListener('load', scheduleRun);
        }

        var observer = new MutationObserver(function(mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var added = mutations[i].addedNodes;
                for (var j = 0; j < added.length; j++) {
                    if (added[j].nodeType === 1) {
                        var el = added[j];
                        // 检查是否包含成员列表
                        if (el.querySelector && el.querySelector('.card-list.mt-md.mb-sm .item-card')) {
                            scheduleRun();
                            return;
                        }
                        if (el.classList && el.classList.contains('card-list') && el.querySelector('.item-card')) {
                            scheduleRun();
                            return;
                        }
                    }
                }
            }
        });
        observer.observe(document.body, { childList: true, subtree: true });
    })();
}
// 功能：装备薄弱点分析模块 - 即时渲染版
// 注册名：initEquipmentWeaknessAnalyzer
function initEquipmentWeaknessAnalyzer() {
    (function() {
        'use strict';
        const EQUIPMENT_CONFIG = {
            '鱼竿': {
                statName: '最大张力',
                breakCauses: ['断竿', '遛鱼终局失败'],
                affectedBy: ['断主线', '断引线', '断钩', '切线', '渔轮损坏'],
                affects: ['主线', '引线', '沉子', '鱼钩', '饵/拟饵']
            },
            '渔轮': {
                statName: '锁轮',
                breakCauses: ['渔轮损坏'],
                affectedBy: [],
                affects: ['主线', '引线', '沉子', '鱼钩', '饵/拟饵', '渔轮自身']
            },
            '鱼线': {
                statName: '最大张力',
                breakCauses: ['断主线', '切线'],
                affectedBy: ['渔轮损坏', '断竿'],
                affects: ['引线', '沉子', '鱼钩', '饵/拟饵']
            },
            '引线': {
                statName: '最大张力',
                breakCauses: ['断引线'],
                affectedBy: ['断主线', '切线', '渔轮损坏', '断竿'],
                affects: ['鱼钩', '饵/拟饵', '沉子']
            },
            '鱼钩': {
                statName: '最大张力',
                breakCauses: ['断钩'],
                affectedBy: ['断主线', '切线', '断引线', '渔轮损坏', '断竿'],
                affects: ['饵/拟饵']
            },
            '沉子': {
                statName: '最大承重', // 假设存在
                breakCauses: [],
                affectedBy: ['断主线', '切线', '断引线', '渔轮损坏', '断竿'],
                affects: []
            },
            '拟饵': {
                statName: '最大承重', // 假设存在
                breakCauses: [],
                affectedBy: ['断主线', '切线', '断引线', '断钩', '渔轮损坏', '断竿'],
                affects: []
            },
            '真饵': {
                statName: '最大承重', // 假设存在
                breakCauses: [],
                affectedBy: ['断主线', '切线', '断引线', '断钩', '渔轮损坏', '断竿'],
                affects: []
            }
        };
        const BREAK_CHAIN = {
            '断钩': ['鱼钩', '饵/拟饵'],
            '断引线': ['引线', '沉子', '鱼钩', '饵/拟饵'],
            '断主线': ['主线', '引线', '沉子', '鱼钩', '饵/拟饵'],
            '切线': ['主线', '引线', '沉子', '鱼钩', '饵/拟饵'],
            '渔轮损坏': ['渔轮', '鱼线', '引线', '沉子', '鱼钩', '饵/拟饵'],
            '断竿': ['鱼竿', '鱼线', '引线', '沉子', '鱼钩', '饵/拟饵']
        };
        const CLASSES = {
            weakest: 'equipment-weakest',
            affected: 'equipment-affected',
            highlight: 'equipment-highlight'
        };
        const STYLES = `
            .${CLASSES.weakest} {
                border: 2px solid #ef4444 !important;
                border-radius: 6px;
                position: relative;
                animation: weakest-pulse 2s infinite;
            }

            .${CLASSES.weakest}::before {
                content: "⚠️ 最薄弱环节";
                position: absolute;
                top: -10px;
                right: 5px;
                background: #ef4444;
                color: white;
                font-size: 10px;
                padding: 2px 6px;
                border-radius: 4px;
                font-weight: bold;
            }

            .${CLASSES.affected} {
                border: 2px solid #fbbf24 !important;
                border-radius: 6px;
            }

            .${CLASSES.highlight} {
                position: relative;
                padding: 2px;
                background: linear-gradient(135deg, rgba(239,68,68,0.1) 0%, rgba(251,191,36,0.1) 100%);
                border-radius: 8px;
                margin-bottom: 8px;
            }

            .equipment-warning-tooltip {
                position: absolute;
                bottom: -5px;
                left: 50%;
                transform: translateX(-50%);
                background: #1e293b;
                color: white;
                padding: 8px 12px;
                border-radius: 6px;
                font-size: 12px;
                white-space: nowrap;
                z-index: 1000;
                box-shadow: 0 4px 6px rgba(0,0,0,0.3);
                opacity: 0;
                transition: opacity 0.2s;
                pointer-events: none;
            }

            .loadout-slot:hover .equipment-warning-tooltip {
                opacity: 1;
            }

            @keyframes weakest-pulse {
                0%, 100% { box-shadow: 0 0 0 0 rgba(239,68,68,0.7); }
                50% { box-shadow: 0 0 0 4px rgba(239,68,68,0); }
            }
        `;
        function injectStyles() {
            if (document.getElementById('equipment-weakness-styles')) return;

            const styleEl = document.createElement('style');
            styleEl.id = 'equipment-weakness-styles';
            styleEl.textContent = STYLES;
            document.head.appendChild(styleEl);
        }
        function extractEquipmentData(slot) {
            const labelEl = slot.querySelector('.loadout-slot-label');
            if (!labelEl) return null;

            const type = labelEl.textContent.trim();
            const config = EQUIPMENT_CONFIG[type];
            if (!config) return null;

            let maxTension = null;
            const statsEl = slot.querySelector('.loadout-slot-stats');

            if (statsEl) {
                const spans = statsEl.querySelectorAll('span');
                for (let i = 0; i < spans.length; i++) {
                    const text = spans[i].textContent;
                    if (text.includes(config.statName)) {
                        const match = text.match(/([\d.]+)/);
                        if (match) {
                            maxTension = parseFloat(match[1]);
                            break;
                        }
                    }
                }
            }
            if (type === '鱼钩' && !maxTension) {
                const tensionTag = slot.querySelector('.hook-strength-result');
                if (tensionTag && tensionTag.textContent.includes('最大张力')) {
                    const match = tensionTag.textContent.match(/最大张力(\d+)/);
                    if (match) {
                        maxTension = parseFloat(match[1]);
                    }
                }
            }

            const nameEl = slot.querySelector('.loadout-slot-name');
            const name = nameEl ? nameEl.textContent.trim() : '';

            return {
                element: slot,
                type: type,
                name: name,
                tension: maxTension,
                config: config
            };
        }
        function analyzeWeakness(equipments) {
            if (equipments.length === 0) return { weakest: null, affected: [] };
            let minTension = Infinity;
            let weakest = null;
            equipments.forEach(eq => {
                if (eq.tension !== null && eq.tension < minTension) {
                    minTension = eq.tension;
                    weakest = eq;
                }
            });

            if (!weakest) return { weakest: null, affected: [] };
            const affected = [];
            const breakEffects = BREAK_CHAIN[weakest.config.breakCauses[0]] || [];
            equipments.forEach(eq => {
                breakEffects.forEach(effect => {
                    if (eq.type.includes(effect) || effect.includes(eq.type)) {
                        if (eq !== weakest && !affected.includes(eq)) {
                            affected.push(eq);
                        }
                    }
                });
            });

            return { weakest, affected };
        }
        function addWarningTooltip(slot, message) {
            const existing = slot.querySelector('.equipment-warning-tooltip');
            if (existing) return;

            const tooltip = document.createElement('div');
            tooltip.className = 'equipment-warning-tooltip';
            tooltip.textContent = message;
            slot.appendChild(tooltip);

            slot.addEventListener('mouseenter', () => {
                tooltip.style.opacity = '1';
            });

            slot.addEventListener('mouseleave', () => {
                tooltip.style.opacity = '0';
            });
        }
        function clearHighlights() {
            document.querySelectorAll(`.${CLASSES.weakest}`).forEach(el => {
                el.classList.remove(CLASSES.weakest);
            });
            document.querySelectorAll(`.${CLASSES.affected}`).forEach(el => {
                el.classList.remove(CLASSES.affected);
            });
            document.querySelectorAll(`.${CLASSES.highlight}`).forEach(el => {
                el.classList.remove(CLASSES.highlight);
            });
            document.querySelectorAll('.equipment-warning-tooltip').forEach(el => {
                el.remove();
            });
        }
        function analyzeEquipmentChain() {
            const loadoutBar = document.querySelector('.loadout-bar');
            if (!loadoutBar) return;
            clearHighlights();
            const slots = loadoutBar.querySelectorAll('.loadout-slot');
            const equipments = [];

            slots.forEach(slot => {
                const data = extractEquipmentData(slot);
                if (data) {
                    equipments.push(data);
                }
            });
            const { weakest, affected } = analyzeWeakness(equipments);
            if (weakest) {
                weakest.element.classList.add(CLASSES.weakest);

                let warningMsg = `最薄弱环节\n张力: ${weakest.tension}`;
                if (weakest.config.breakCauses.length > 0) {
                    warningMsg += `\n若${weakest.config.breakCauses[0]}，会损毁：${BREAK_CHAIN[weakest.config.breakCauses[0]]?.join(', ')}`;
                }
                addWarningTooltip(weakest.element, warningMsg);
            }

            affected.forEach(eq => {
                eq.element.classList.add(CLASSES.affected);

                let warningMsg = `连带影响\n若上方装备断裂，此装备会被一同损毁`;
                addWarningTooltip(eq.element, warningMsg);
            });
            if (weakest) {
                loadoutBar.classList.add(CLASSES.highlight);
            }
        }
        function init() {
            injectStyles();
            analyzeEquipmentChain();
            const observer = new MutationObserver((mutations) => {
                let needsUpdate = false;
                for (const mutation of mutations) {
                    if (mutation.type === 'childList') {
                        for (const node of mutation.addedNodes) {
                            if (node.nodeType === Node.ELEMENT_NODE) {
                                if (node.classList &&
                                    (node.classList.contains('loadout-slot') ||
                                     node.querySelector('.loadout-bar') ||
                                     node.querySelector('.loadout-slot'))) {
                                    needsUpdate = true;
                                    break;
                                }
                            }
                        }
                        for (const node of mutation.target.querySelectorAll?.(`
                            .loadout-slot-name,
                            .loadout-slot-stats span,
                            .loadout-slot-meta,
                            .hook-strength-result
                        `) || []) {
                            if (mutation.target.contains(node)) {
                                needsUpdate = true;
                                break;
                            }
                        }
                    }
                    if (needsUpdate) break;
                }
                if (needsUpdate) {
                    if (window._weaknessAnalysisTimeout) {
                        clearTimeout(window._weaknessAnalysisTimeout);
                    }
                    window._weaknessAnalysisTimeout = setTimeout(() => {
                        analyzeEquipmentChain();
                        window._weaknessAnalysisTimeout = null;
                    }, 300);
                }
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true,
                characterData: true
            });
        }
        if (document.readyState === 'complete') {
            setTimeout(init, 2000);
        } else {
            window.addEventListener('load', () => {
                setTimeout(init, 2000);
            });
        }

    })();
}
// 功能：隐藏登录身份信息模块（改进版）
// 注册名：initHideLoginIdentity
function initHideLoginIdentity() {
    (function() {
        'use strict';

        console.log('[隐藏登录身份] 模块启动 - 单页应用优化版');

        // 方案A：重置全局变量（允许重新运行）
        window.__hideLoginIdentityLoaded = false;

        // 方案B：使用更智能的检查（推荐）
        const MODULE_NAME = 'hideLoginIdentity_V2';
        if (window[MODULE_NAME]?.isActive) {
            console.log('[隐藏登录身份] 模块已激活，跳过初始化');
            // 但继续执行下面的观察器设置，因为DOM可能变了
        }

        // 设置模块状态
        window.hideLoginIdentity_V2 = {
            isActive: true,
            lastProcessedUID: null  // 记录上次处理的元素UID
        };

        // 核心函数：快速删除元素
        function removeLoginIdentity() {
            // 查找目标元素
            const targetSelector = '.profile-card .text-xs.text-muted';
            const elements = document.querySelectorAll(targetSelector);

            for (let i = 0; i < elements.length; i++) {
                const element = elements[i];

                // 检查是否包含登录身份信息
                if (element.textContent.includes('登录身份：') ||
                    element.textContent.match(/\d{11}/)) {

                    // 生成元素唯一ID（用于避免重复处理）
                    const elementUID = element.innerHTML + element.className + element.parentNode?.className;

                    // 如果是新元素才处理
                    if (window.hideLoginIdentity_V2.lastProcessedUID !== elementUID) {
                        console.log('[隐藏登录身份] 发现新登录身份元素，正在删除...');

                        // 直接删除元素（最简单高效）
                        element.remove();

                        // 标记已处理
                        window.hideLoginIdentity_V2.lastProcessedUID = elementUID;
                        window.hideLoginIdentity_V2.lastProcessedTime = Date.now();

                        return true;
                    }
                }
            }
            return false;
        }

        // 监听SPA页面切换
        function setupSPAListener() {
            let lastUrl = location.href;

            // 定期检查URL变化
            setInterval(() => {
                if (location.href !== lastUrl) {
                    console.log('[隐藏登录身份] 检测到SPA页面切换:', lastUrl, '→', location.href);
                    lastUrl = location.href;

                    // 清除之前处理的记录，因为DOM是全新的
                    window.hideLoginIdentity_V2.lastProcessedUID = null;

                    // 重新处理
                    setTimeout(removeLoginIdentity, 500); // 等新DOM加载
                }
            }, 300);

            // 监听history API（单页应用常用）
            const originalPushState = history.pushState;
            const originalReplaceState = history.replaceState;

            history.pushState = function() {
                originalPushState.apply(this, arguments);
                setTimeout(() => {
                    window.hideLoginIdentity_V2.lastProcessedUID = null;
                    removeLoginIdentity();
                }, 300);
            };

            history.replaceState = function() {
                originalReplaceState.apply(this, arguments);
                setTimeout(() => {
                    window.hideLoginIdentity_V2.lastProcessedUID = null;
                    removeLoginIdentity();
                }, 300);
            };

            // 监听popstate事件（浏览器后退/前进）
            window.addEventListener('popstate', () => {
                setTimeout(() => {
                    window.hideLoginIdentity_V2.lastProcessedUID = null;
                    setTimeout(removeLoginIdentity, 400);
                }, 100);
            });
        }

        // 主初始化
        function init() {
            console.log('[隐藏登录身份] 初始化...');

            // 第一步：立即删除现有元素
            const removed = removeLoginIdentity();
            console.log(`[隐藏登录身份] 立即删除结果: ${removed ? '成功' : '暂未找到'}`);

            // 第二步：设置DOM变化监听
            const observer = new MutationObserver((mutations) => {
                // 快速检查是否有新元素
                const found = document.querySelector('.profile-card .text-xs.text-muted');
                if (found && !found.classList.contains('login-identity-removed')) {
                    setTimeout(removeLoginIdentity, 50);
                }
            });

            // 只监听body的子节点变化（性能更好）
            observer.observe(document.body, {
                childList: true,
                subtree: false
            });

            // 第三步：设置SPA监听
            setupSPAListener();

            // 第四步：定期检查（兜底方案）
            setInterval(removeLoginIdentity, 2000);

            console.log('[隐藏登录身份] 初始化完成，监听器已启动');
        }

        // 立即执行
        init();

    })();
}
// 功能：商品卡片增强显示 - 显示号数、颜色及对应色框
// 注册名：initItemCardEnhance
function initItemCardEnhance() {
    (function() {
        'use strict';

        if (window.__itemCardEnhanceLoaded) return;
        window.__itemCardEnhanceLoaded = true;

        // ============================================================
        // 颜色映射表
        // ============================================================
        const COLOR_MAP = {
            "white": "#FFFFFF",
            "gold": "#FFD700",
            "silver": "#C0C0C0",
            "chartreuse": "#7FFF00",
            "brown": "#8B4513",
            "bone": "#E3DAC9",
            "green": "#008000",
            "smelt": "#F5F5F5",
            "ayu": "#556B2F",
            "pearl": "#FDEEF4",
            "sardine": "#CDCDCD",
            "mackerel": "#2F4F4F",
            "skipjack": "#CD853F",
            "silver_blue": "#87CEEB",
            "ghost_shad": "#F0F8FF",
            "silver_chartreuse": "#ADFF2F",
            "black_gold": "#1A1A1A",
            "green_gold": "#6B8E23",
            "silver_gold": "#E6BE8A",
            "bone_silver": "#F5F5F5",
            "black_red": "#8B0000",
            "half_ayu": "#696969",
            "blue_pink": "#FF69B4",
            "pink_silver": "#DA70D6",
            "blue_silver": "#4169E1",
            "sardine_black": "#696969",
            "blue_sardine": "#00CED1",
            "blue_chrome": "#0047AB",
            "bone_sardine": "#FAEBD7",
            "blue_black": "#000033",
            "purple_silver": "#9370DB",
            "flying_fish": "#E0FFFF",
            "flying_mackerel": "#2E8B57",
            "holo_mullet": "#87CEFA",
            "chrome_blue": "#0000FF",
            "pink_blue": "#E6E6FA",
            "blue_black_silver": "#191970",
            "abyss_silver": "#000000",
            "crown_silver": "#B8860B",
            "bone_blue": "#ADD8E6",
            "flying_sardine": "#BDB76B",
            "abyss_glow": "#00FF00"
        };

        // ============================================================
        // 颜色名称的中文翻译
        // ============================================================
        const COLOR_NAME_CN = {
            "white": "白色",
            "gold": "金色",
            "silver": "银色",
            "chartreuse": "黄绿色",
            "brown": "棕色",
            "bone": "骨色",
            "green": "绿色",
            "smelt": "银白色",
            "ayu": "香鱼色",
            "pearl": "珍珠白",
            "sardine": "沙丁鱼色",
            "mackerel": "鲭鱼色",
            "skipjack": "鲣鱼色",
            "silver_blue": "银蓝色",
            "ghost_shad": "幽灵鲱色",
            "silver_chartreuse": "银黄绿色",
            "black_gold": "黑金色",
            "green_gold": "绿金色",
            "silver_gold": "银金色",
            "bone_silver": "骨银色",
            "black_red": "黑红色",
            "half_ayu": "半香鱼色",
            "blue_pink": "蓝粉色",
            "pink_silver": "粉银色",
            "blue_silver": "蓝银色",
            "sardine_black": "黑沙丁鱼色",
            "blue_sardine": "蓝沙丁鱼色",
            "blue_chrome": "蓝铬色",
            "bone_sardine": "骨沙丁鱼色",
            "blue_black": "蓝黑色",
            "purple_silver": "紫银色",
            "flying_fish": "飞鱼色",
            "flying_mackerel": "飞鲭色",
            "holo_mullet": "全息鲻鱼色",
            "chrome_blue": "铬蓝色",
            "pink_blue": "粉蓝色",
            "blue_black_silver": "蓝黑银色",
            "abyss_silver": "深渊银",
            "crown_silver": "皇冠银",
            "bone_blue": "骨蓝色",
            "flying_sardine": "飞沙丁鱼色",
            "abyss_glow": "深渊荧光"
        };

        // ============================================================
        // 根据商品名称查找数据库
        // ============================================================
        function findItemByName(itemName) {
            const ITEM_DATABASE = window.ITEM_DATABASE || {};
            const cleanName = itemName.trim().replace(/\s+/g, ' ');

            for (const [id, item] of Object.entries(ITEM_DATABASE)) {
                if (item.name === cleanName ||
                    item.name.includes(cleanName) ||
                    cleanName.includes(item.name.split('·')[0].trim())) {
                    return item;
                }
            }

            const namePrefix = cleanName.split('·')[0]?.trim() || cleanName.split(' ')[0];
            for (const [id, item] of Object.entries(ITEM_DATABASE)) {
                if (item.name.startsWith(namePrefix)) {
                    return item;
                }
            }

            return null;
        }

        // ============================================================
        // 增强单个卡片
        // ============================================================
        let matchCount = 0;
        let missCount = 0;

        function enhanceCard(cardElement) {
            if (cardElement.dataset.enhanced === 'true') return;

            const nameElement = cardElement.querySelector('.item-name');
            if (!nameElement) return;

            const itemName = nameElement.textContent.trim();
            const itemData = findItemByName(itemName);

            if (!itemData) {
                missCount++;
                return;
            }

            cardElement.dataset.enhanced = 'true';
            matchCount++;

            const colorHex = COLOR_MAP[itemData.color] || '#CCCCCC';
            const colorName = COLOR_NAME_CN[itemData.color] || itemData.color;
            cardElement.style.boxShadow = `inset 0 0 0 4px ${colorHex}`;
            cardElement.style.borderRadius = '8px';

            const metaContainer = cardElement.querySelector('.shop-card-meta');
            if (metaContainer) {
                const sizeSpan = document.createElement('span');
                sizeSpan.textContent = `号数: ${itemData.size}`;
                sizeSpan.className = 'enhanced-meta';

                const colorSpan = document.createElement('span');
                colorSpan.textContent = `颜色: ${colorName}`;
                colorSpan.className = 'enhanced-meta';
                colorSpan.style.color = colorHex;
                colorSpan.style.fontWeight = 'bold';
                metaContainer.appendChild(document.createTextNode(' '));
                metaContainer.appendChild(sizeSpan);
                metaContainer.appendChild(document.createTextNode(' '));
                metaContainer.appendChild(colorSpan);
            }

            const contentDiv = cardElement.querySelector('.square-item-card-content');
            if (contentDiv) {
                const colorIndicator = document.createElement('div');
                colorIndicator.className = 'enhanced-color-indicator';
                colorIndicator.style.cssText = `
                    height: 3px;
                    background: linear-gradient(to right, ${colorHex}88, ${colorHex}, ${colorHex}88);
                    border-radius: 0 0 4px 4px;
                    margin-top: 4px;
                    opacity: 0.8;
                `;
                contentDiv.appendChild(colorIndicator);
            }
        }

        function enhanceAllCards() {
            const cards = document.querySelectorAll('.card.item-card.square-item-card.shop-grid-card');

            matchCount = 0;
            missCount = 0;

            cards.forEach(card => {
                try {
                    enhanceCard(card);
                } catch (error) {
                    // 静默处理
                }
            });

            if (cards.length > 0) {
                console.log(`[卡片增强] ${cards.length} 张卡片 | 增强: ${matchCount} | 未匹配: ${missCount}`);
            }
        }

        // ============================================================
        // 观察器
        // ============================================================
        function setupObserver() {
            const observer = new MutationObserver((mutations) => {
                let hasNewCards = false;

                for (const mutation of mutations) {
                    if (mutation.type === 'childList') {
                        for (const node of mutation.addedNodes) {
                            if (node.nodeType === Node.ELEMENT_NODE) {
                                if (node.classList?.contains('shop-grid-card') ||
                                    node.querySelector?.('.shop-grid-card')) {
                                    hasNewCards = true;
                                    break;
                                }
                            }
                        }
                    }
                }

                if (hasNewCards) {
                    setTimeout(enhanceAllCards, 300);
                }
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        }

        // ============================================================
        // 样式注入
        // ============================================================
        function injectStyles() {
            const styleId = 'item-card-enhance-styles';
            if (document.getElementById(styleId)) return;

            const styles = `
                .card.item-card.shop-grid-card[data-enhanced="true"] {
                    transition: box-shadow 0.3s ease;
                    position: relative;
                }

                .card.item-card.shop-grid-card[data-enhanced="true"]:hover {
                    box-shadow: inset 0 0 0 5px currentColor, 0 4px 12px rgba(0,0,0,0.15) !important;
                }

                .enhanced-meta {
                    display: inline-block;
                    padding: 1px 4px;
                    font-size: 0.85em;
                    background: rgba(255,255,255,0.1);
                    border-radius: 3px;
                }

                .enhanced-color-indicator {
                    transition: opacity 0.2s ease;
                }

                .card.item-card.shop-grid-card:hover .enhanced-color-indicator {
                    opacity: 1 !important;
                }
            `;

            const styleElement = document.createElement('style');
            styleElement.id = styleId;
            styleElement.textContent = styles;
            document.head.appendChild(styleElement);
        }

        // ============================================================
        // SPA 路由监听
        // ============================================================
        function setupSPAListener() {
            let lastUrl = location.href;

            setInterval(() => {
                if (location.href !== lastUrl) {
                    lastUrl = location.href;
                    document.querySelectorAll('.shop-grid-card[data-enhanced="true"]').forEach(card => {
                        card.dataset.enhanced = 'false';
                    });
                    setTimeout(enhanceAllCards, 500);
                }
            }, 500);

            const originalPushState = history.pushState;
            history.pushState = function() {
                originalPushState.apply(this, arguments);
                setTimeout(enhanceAllCards, 300);
            };

            window.addEventListener('popstate', () => {
                setTimeout(enhanceAllCards, 400);
            });
        }

        // ============================================================
        // 初始化
        // ============================================================
        function init() {
            window.__onItemDbReady(function() {
                const dbSize = Object.keys(window.ITEM_DATABASE || {}).length;
                console.log(`[卡片增强] 数据就绪 (${dbSize} 条) | 开始初始化`);

                injectStyles();
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', () => {
                        setTimeout(enhanceAllCards, 1000);
                        setupObserver();
                        setupSPAListener();
                    });
                } else {
                    setTimeout(enhanceAllCards, 800);
                    setupObserver();
                    setupSPAListener();
                }
                setInterval(enhanceAllCards, 5000);
            });
        }

        init();

        // ============================================================
        // 对外 API
        // ============================================================
        window.ItemCardEnhance = {
            refresh: enhanceAllCards,
            getItemData: findItemByName,
            getColorHex: (colorName) => COLOR_MAP[colorName] || '#CCCCCC',
            getColorNameCN: (colorName) => COLOR_NAME_CN[colorName] || colorName,
            status: () => ({
                enhanced: document.querySelectorAll('.shop-grid-card[data-enhanced="true"]').length,
                total: document.querySelectorAll('.shop-grid-card').length
            })
        };

    })();
}


    // ============================================================
    // 根据开关状态启动功能
    // ============================================================
    const INIT_MAP = {
        lureSoftness: initLureSoftness,
        fishSort: initFishSort,
        boatSort: initBoatSort,
        waterLayer: initWaterLayer,
        fishLogColor: initFishLogColor,
        catchInterval: initCatchInterval,
        reelEnhance: initReelEnhance,
        shopCardEnhance: initShopCardEnhance,
        assemblySim: initAssemblySim,
        hookStrength: initHookStrength,
        fishCardGradeColor: initFishCardGradeColor,
        fishCardGlow: initFishCardGlow,
        challengeFishInfo: initChallengeFishInfo,
        realtimeChart: initRealtimeChart,
        fishWeightGlow: initFishWeightGlow,
        weeklyTarget: initWeeklyTarget,
        catchSummary: initCatchSummary,
        specializationSummary: initSpecializationSummary,
        fishStaminaUI: initFishStaminaUI,
        dynamicBorder: initDynamicBorder,
        rankingStyle: initRankingStyle,
        sortChallenges: initSortChallenges,
        specializationSim: initSpecializationSim,
        fishValuePerKg: initFishValuePerKg,
        catchPlate: initCatchPlate,
        intervalTrendChart: initIntervalTrendChart,
        boatMemberSort: initBoatMemberSort,
        EquipmentWeaknessAnalyzer: initEquipmentWeaknessAnalyzer,
        HideLoginIdentity: initHideLoginIdentity,
        ItemCardEnhance: initItemCardEnhance,

    };

    FEATURES.forEach(f => {
        if (isEnabled(f.id)) {
            const initFn = INIT_MAP[f.id];
            if (initFn) initFn();
        }
    });

    registerMenuCommands();

})();
