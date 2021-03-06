﻿using System;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using Liquid.NET.Constants;
using Liquid.NET.Utils;

namespace Liquid.NET.Filters.Array 
{
    public class MapFilter: FilterExpression<ILiquidValue , ILiquidValue>
    {
        private readonly LiquidString _selector;

        public MapFilter(LiquidString selector)
        {
            _selector = selector;
        }

        public override LiquidExpressionResult ApplyTo(ITemplateContext ctx, ILiquidValue liquidExpression)
        {
            //return LiquidExpressionResult.Error("Can't map that object type.  It is not an array or a hash.");
            return LiquidExpressionResult.Success(new None<ILiquidValue>());
        }

        public override LiquidExpressionResult ApplyTo(ITemplateContext ctx, LiquidCollection liquidArrayExpression)
        {
            var list = liquidArrayExpression.Select(x => x.HasValue
                ? FieldAccessor.TryField(ctx, x.Value, _selector.StringVal)
                : LiquidExpressionResult.ErrorOrNone(ctx, _selector.StringVal)).ToList();
                //new None<ILiquidValue>()).ToList();
            return list.Any(x => x.IsError) ? 
                list.First(x => x.IsError) : 
                LiquidExpressionResult.Success(new LiquidCollection(list.Select(x => x.SuccessResult).ToList()));
        }

        public override LiquidExpressionResult ApplyTo(ITemplateContext ctx, LiquidHash liquidLiquidHash)
        {
            String propertyNameString = ValueCaster.RenderAsString((ILiquidValue)_selector);

            return LiquidExpressionResult.Success(liquidLiquidHash.ValueAt(propertyNameString));
            
        }

    }
}
