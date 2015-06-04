function openerp_pos_basewidget(instance, module){ //module is instance.point_of_sale

    var round_di = instance.web.round_decimals;
    var round_pr = instance.web.round_precision;

    // This is a base class for all Widgets in the POS. It exposes relevant data to the 
    // templates : 
    // - widget.currency : { symbol: '$' | '€' | ..., position: 'before' | 'after }
    // - widget.format_currency(amount) : this method returns a formatted string based on the
    //   symbol, the position, and the amount of money.
    // if the PoS is not fully loaded when you instanciate the widget, the currency might not
    // yet have been initialized. Use __build_currency_template() to recompute with correct values
    // before rendering.

    module.PosBaseWidget = instance.web.Widget.extend({
        init:function(parent,options){
            this._super(parent);
            options = options || {};
            this.pos = options.pos || (parent ? parent.pos : undefined);
            this.pos_widget = options.pos_widget || (parent ? parent.pos_widget : undefined);
        },
        format_currency: function(amount,precision){
            var currency = (this.pos && this.pos.currency) ? this.pos.currency : {symbol:'$', position: 'after', rounding: 1, decimals: 0};
            var decimals = currency.decimals;
            decimals = 0;

            if (precision && (typeof this.pos.dp[precision]) !== undefined) {
                decimals = this.pos.dp[precision];
            }

            if (typeof amount === 'number') {
                var am = amount
                amount = round_di(amount,decimals).toFixed(decimals);
                var negative = amount[0] === '-';
                amount = (negative ? amount.slice(1) : amount);
                amount = amount.replace(/\d(?=(\d{3})+(\.|$))/g, '$&.');
                // amount = (negative ? '-' : '') + instance.web.intersperse(amount, [3,6,9,12], '.');
                // amount = insert_sep(amount)
            }

            if (currency.position === 'after') {
                return amount + ' ' + (currency.symbol || '');
            } else {
                return (currency.symbol || '') + ' ' + amount;
            }
        },
        show: function(){
            this.$el.removeClass('oe_hidden');
        },
        hide: function(){
            this.$el.addClass('oe_hidden');
        },
        format_pr: function(value,precision){
            var decimals = precision > 0 ? Math.max(0,Math.ceil(Math.log(1.0/precision) / Math.log(10))) : 0;
            return value.toFixed(decimals);
        },
    });

}
