/*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package routing

import (
	"context"

	iter8v1alpha2 "github.com/iter8-tools/iter8/pkg/apis/iter8/v1alpha2"
	"github.com/iter8-tools/iter8/pkg/controller/experiment/routing/router"
	"github.com/iter8-tools/iter8/pkg/controller/experiment/routing/router/istio"
)

// GetRouter returns the platform specific implementation of Router interface
func GetRouter(context context.Context, instance *iter8v1alpha2.Experiment) router.Interface {
	return istio.GetRouter(context, instance)
}
